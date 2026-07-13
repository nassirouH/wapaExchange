import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import * as crypto from 'crypto';

export interface SumsubApplicant {
  id: string;
  externalUserId: string;
  createdAt: string;
}

export interface SumsubSdkToken {
  token: string;
  userId: string;
}

/**
 * Sumsub uses HMAC-SHA256 signed requests with two headers:
 *   X-App-Token, X-App-Access-Sig, X-App-Access-Ts
 * Signature = HMAC_SHA256(secret, ts + method + path + body)
 * Reference: https://developers.sumsub.com/api-reference/#authentication
 */
@Injectable()
export class SumsubClient {
  private readonly logger = new Logger(SumsubClient.name);
  private readonly baseUrl = 'https://api.sumsub.com';
  private readonly appToken = process.env.SUMSUB_APP_TOKEN ?? '';
  private readonly secret = process.env.SUMSUB_SECRET_KEY ?? '';
  private readonly levelName = process.env.SUMSUB_LEVEL_NAME ?? 'basic-kyc-level';

  private get enabled() {
    return Boolean(this.appToken && this.secret);
  }

  async createApplicant(externalUserId: string): Promise<SumsubApplicant> {
    if (!this.enabled) throw new ServiceUnavailableException('KYC provider not configured.');
    const body = JSON.stringify({ externalUserId, type: 'individual' });
    const path = `/resources/applicants?levelName=${encodeURIComponent(this.levelName)}`;
    const res = await this.signedFetch('POST', path, body);
    const json = (await res.json()) as { id: string; createdAt: string };
    return { id: json.id, externalUserId, createdAt: json.createdAt };
  }

  async generateSdkToken(applicantId: string, externalUserId: string): Promise<SumsubSdkToken> {
    if (!this.enabled) throw new ServiceUnavailableException('KYC provider not configured.');
    const path = `/resources/accessTokens?userId=${encodeURIComponent(externalUserId)}&levelName=${encodeURIComponent(this.levelName)}&ttlInSecs=1800`;
    const res = await this.signedFetch('POST', path, '');
    const json = (await res.json()) as { token: string; userId: string };
    return json;
  }

  async getApplicantStatus(applicantId: string): Promise<'pending' | 'approved' | 'rejected'> {
    if (!this.enabled) throw new ServiceUnavailableException('KYC provider not configured.');
    const path = `/resources/applicants/${applicantId}/status`;
    const res = await this.signedFetch('GET', path, '');
    const json = (await res.json()) as { reviewStatus?: string; reviewResult?: { reviewAnswer?: string } };
    if (json.reviewStatus !== 'completed') return 'pending';
    return json.reviewResult?.reviewAnswer === 'GREEN' ? 'approved' : 'rejected';
  }

  /**
   * Verifies a Sumsub webhook payload signature.
   * Sumsub sends `X-Payload-Digest` = HMAC_SHA256(webhook-secret, rawBody)
   */
  verifyWebhook(rawBody: string, signature: string): boolean {
    const secret = process.env.SUMSUB_WEBHOOK_SECRET;
    if (!secret) return false;
    const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
  }

  private async signedFetch(method: 'GET' | 'POST', path: string, body: string): Promise<Response> {
    const ts = Math.floor(Date.now() / 1000).toString();
    const sigPayload = ts + method + path + body;
    const sig = crypto.createHmac('sha256', this.secret).update(sigPayload).digest('hex');

    const res = await fetch(this.baseUrl + path, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-App-Token': this.appToken,
        'X-App-Access-Ts': ts,
        'X-App-Access-Sig': sig,
      },
      body: body || undefined,
    });

    if (!res.ok) {
      const text = await res.text();
      this.logger.error(`Sumsub ${method} ${path} failed: ${res.status} ${text}`);
      throw new ServiceUnavailableException(`KYC provider error (${res.status}).`);
    }
    return res;
  }
}
