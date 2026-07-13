import * as crypto from 'crypto';
import { StripeService } from './stripe.service';

/**
 * Stripe signs webhook bodies as:
 *   t=<unix_ts>,v1=HMAC_SHA256(<secret>, "<unix_ts>.<raw_body>")
 *
 * We exercise the real `constructEvent` path of the Stripe SDK by signing a
 * known-good payload with a known secret, then assert the SDK accepts ours
 * and rejects a tampered one.
 */
function signStripePayload(payload: string, secret: string, timestamp = Math.floor(Date.now() / 1000)) {
  const signed = `${timestamp}.${payload}`;
  const v1 = crypto.createHmac('sha256', secret).update(signed).digest('hex');
  return { header: `t=${timestamp},v1=${v1}`, timestamp };
}

describe('StripeService.constructEvent', () => {
  const WEBHOOK_SECRET = 'whsec_test_abc123';
  const STRIPE_SECRET = 'sk_test_xyz';
  let service: StripeService;

  beforeAll(() => {
    process.env.STRIPE_SECRET_KEY = STRIPE_SECRET;
    process.env.STRIPE_WEBHOOK_SECRET = WEBHOOK_SECRET;
  });

  beforeEach(() => {
    service = new StripeService();
  });

  it('accepts a correctly signed payload and returns the parsed event', () => {
    const event = {
      id: 'evt_1', type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_1', metadata: { transfer_id: 'tx_abc' } } },
    };
    const body = JSON.stringify(event);
    const { header } = signStripePayload(body, WEBHOOK_SECRET);
    const parsed = service.constructEvent(body, header);
    expect(parsed.type).toBe('payment_intent.succeeded');
    expect((parsed.data.object as { metadata: { transfer_id: string } }).metadata.transfer_id).toBe('tx_abc');
  });

  it('rejects a tampered body even with a valid-looking signature', () => {
    const body = JSON.stringify({ id: 'evt_1', type: 'payment_intent.succeeded' });
    const { header } = signStripePayload(body, WEBHOOK_SECRET);
    const tampered = body.replace('payment_intent.succeeded', 'payment_intent.payment_failed');
    expect(() => service.constructEvent(tampered, header)).toThrow();
  });

  it('rejects a payload signed with the wrong secret', () => {
    const body = JSON.stringify({ id: 'evt_1', type: 'payment_intent.succeeded' });
    const { header } = signStripePayload(body, 'whsec_wrong_secret');
    expect(() => service.constructEvent(body, header)).toThrow();
  });

  it('rejects very old timestamps (replay protection)', () => {
    const body = JSON.stringify({ id: 'evt_1', type: 'payment_intent.succeeded' });
    const oldTs = Math.floor(Date.now() / 1000) - 60 * 60; // 1h ago
    const { header } = signStripePayload(body, WEBHOOK_SECRET, oldTs);
    // Stripe SDK enforces a default tolerance of 5 minutes.
    expect(() => service.constructEvent(body, header)).toThrow();
  });

  it('rejects a malformed signature header', () => {
    const body = JSON.stringify({ id: 'evt_1' });
    expect(() => service.constructEvent(body, 'not-a-valid-header')).toThrow();
  });
});
