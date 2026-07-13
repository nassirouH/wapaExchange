import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';

export interface ThunesPayoutRequest {
  externalId: string; // our transfer id
  destinationCountry: string; // ISO alpha-2
  receiveCurrency: string;
  receiveAmount: number;
  payoutMethod: 'mobile_money' | 'bank_transfer';
  mobileMoneyProvider?: string | null;
  mobileMoneyNumber?: string | null;
  bankName?: string | null;
  bankAccountNumber?: string | null;
  recipientFullName: string;
}

export interface ThunesPayoutResponse {
  partnerTransactionId: string;
  status: 'CONFIRMED' | 'COMPLETED' | 'CANCELLED' | 'REJECTED';
}

/**
 * Thunes B2B Payments API. Auth = HTTP Basic with API key + secret (sandbox).
 * Reference: https://developers.thunes.com/reference
 *
 * For MVP we expose a single `createPayout` that picks a "quote" service-side
 * (the Thunes quotation step) and then confirms it. Two-step API in reality;
 * collapsed here for clarity.
 */
@Injectable()
export class ThunesClient {
  private readonly logger = new Logger(ThunesClient.name);
  private readonly baseUrl = process.env.THUNES_BASE_URL ?? 'https://api-sandbox.thunes.com';
  private readonly apiKey = process.env.THUNES_API_KEY ?? '';
  private readonly apiSecret = process.env.THUNES_API_SECRET ?? '';

  private get enabled() {
    return Boolean(this.apiKey && this.apiSecret);
  }

  async createPayout(req: ThunesPayoutRequest): Promise<ThunesPayoutResponse> {
    if (!this.enabled) throw new ServiceUnavailableException('Payout provider not configured.');

    // Step 1: create a quotation
    const quotation = await this.call('POST', '/v2/money-transfer/quotations', {
      external_id: req.externalId,
      payer: { id: this.payerIdFor(req) },
      source: { amount: 0, currency: 'EUR' },
      destination: { amount: req.receiveAmount, currency: req.receiveCurrency },
    });
    const quotationId = (quotation as { id: string }).id;

    // Step 2: confirm the transaction
    const txn = (await this.call('POST', `/v2/money-transfer/quotations/${quotationId}/transactions`, {
      credit_party: this.buildCreditParty(req),
      sender: { firstname: 'wapaExchange', lastname: 'Customer' }, // licensed partner is the AML-record-holder
      external_id: req.externalId,
    })) as { id: string; status: string };

    return {
      partnerTransactionId: txn.id,
      status: txn.status as ThunesPayoutResponse['status'],
    };
  }

  private payerIdFor(req: ThunesPayoutRequest): number {
    // In production this is a lookup against Thunes /payers — different payer IDs per
    // country + method (e.g. "Orange Money Senegal" vs "MTN Ghana"). Hardcoded here for MVP.
    if (req.payoutMethod === 'mobile_money') {
      if (req.destinationCountry === 'SN' && req.mobileMoneyProvider === 'orange') return 1101;
      if (req.destinationCountry === 'CI' && req.mobileMoneyProvider === 'orange') return 1102;
      if (req.destinationCountry === 'GH' && req.mobileMoneyProvider === 'mtn') return 1103;
      if (req.destinationCountry === 'KE') return 1104; // M-Pesa
    }
    if (req.payoutMethod === 'bank_transfer') {
      if (req.destinationCountry === 'NG') return 2001;
      if (req.destinationCountry === 'CI') return 2002;
    }
    throw new ServiceUnavailableException(`No Thunes payer configured for ${req.destinationCountry}/${req.payoutMethod}.`);
  }

  private buildCreditParty(req: ThunesPayoutRequest) {
    const [first, ...rest] = req.recipientFullName.split(' ');
    const last = rest.join(' ') || first;
    if (req.payoutMethod === 'mobile_money') {
      return {
        firstname: first,
        lastname: last,
        msisdn: req.mobileMoneyNumber ?? '',
      };
    }
    return {
      firstname: first,
      lastname: last,
      bank_account_number: req.bankAccountNumber ?? '',
      bank_name: req.bankName ?? '',
    };
  }

  private async call(method: 'POST' | 'GET', path: string, body?: unknown): Promise<unknown> {
    const auth = Buffer.from(`${this.apiKey}:${this.apiSecret}`).toString('base64');
    const res = await fetch(this.baseUrl + path, {
      method,
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) {
      const text = await res.text();
      this.logger.error(`Thunes ${method} ${path} failed: ${res.status} ${text}`);
      throw new ServiceUnavailableException(`Payout provider error (${res.status}).`);
    }
    return res.json();
  }
}
