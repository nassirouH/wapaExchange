import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import Stripe from 'stripe';

export interface PayinIntent {
  id: string;
  client_secret: string;
  status: string;
}

@Injectable()
export class StripeService {
  private readonly logger = new Logger(StripeService.name);
  private readonly client: Stripe | null;

  constructor() {
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) {
      this.logger.warn('STRIPE_SECRET_KEY missing — pay-in calls will fail with 503.');
      this.client = null;
    } else {
      this.client = new Stripe(key, {
        apiVersion: '2024-06-20' as Stripe.LatestApiVersion,
        appInfo: { name: 'wapaExchange', version: '0.1.0' },
      });
    }
  }

  async createPayinIntent(params: {
    transferId: string;
    userId: string;
    amount: number; // EUR units
    method: 'apple_pay' | 'card' | 'sepa' | 'open_banking';
  }): Promise<PayinIntent> {
    if (!this.client) throw new ServiceUnavailableException('Pay-in provider not configured.');

    const paymentMethodTypes: Stripe.PaymentIntentCreateParams.PaymentMethodType[] =
      params.method === 'sepa'
        ? ['sepa_debit']
        : params.method === 'open_banking'
          ? ['ideal'] // approximate — production uses pay-by-bank in supported regions
          : ['card']; // covers Apple Pay / Google Pay via card

    const intent = await this.client.paymentIntents.create({
      amount: Math.round(params.amount * 100), // cents
      currency: 'eur',
      payment_method_types: paymentMethodTypes,
      metadata: {
        transfer_id: params.transferId,
        user_id: params.userId,
      },
      // Funds must NOT credit our balance — they will be transferred to the payout PSP
      // via a separate settlement flow operated by the licensed partner.
      capture_method: 'automatic',
    });

    return {
      id: intent.id,
      client_secret: intent.client_secret ?? '',
      status: intent.status,
    };
  }

  /**
   * Verifies a Stripe webhook signature against the raw body.
   * Caller must pass the RAW request body (Buffer or string), not the parsed JSON.
   */
  constructEvent(rawBody: Buffer | string, signature: string): Stripe.Event {
    if (!this.client) throw new ServiceUnavailableException('Pay-in provider not configured.');
    const secret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!secret) throw new ServiceUnavailableException('Stripe webhook secret missing.');
    return this.client.webhooks.constructEvent(rawBody, signature, secret);
  }
}
