import {
  BadRequestException,
  Body,
  Controller,
  Headers,
  HttpCode,
  Logger,
  Post,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { StripeService } from '../../integrations/stripe/stripe.service';
import { SumsubClient } from '../../integrations/sumsub/sumsub.client';
import { TransfersService } from '../transfers/transfers.service';

@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly stripe: StripeService,
    private readonly sumsub: SumsubClient,
    private readonly transfers: TransfersService,
  ) {}

  @Post('payin/stripe')
  @HttpCode(200)
  async stripePayin(
    @Headers('stripe-signature') signature: string,
    @Req() req: RawBodyRequest<Request>,
  ) {
    if (!signature) throw new BadRequestException('Missing stripe-signature.');
    const raw = req.rawBody;
    if (!raw) throw new BadRequestException('Raw body not available.');

    const event = this.stripe.constructEvent(raw, signature);
    const obj = event.data.object as { id: string; metadata?: { transfer_id?: string } };
    const transferId = obj.metadata?.transfer_id;
    if (!transferId) return { ok: true };

    switch (event.type) {
      case 'payment_intent.succeeded':
        await this.transitionTransfer(transferId, 'payin_received', 'webhook:stripe', event);
        await this.transfers.enqueuePayout(transferId);
        break;
      case 'payment_intent.payment_failed':
        await this.transitionTransfer(transferId, 'failed', 'webhook:stripe', event);
        break;
      default:
        this.logger.debug(`Stripe event ${event.type} ignored.`);
    }
    return { ok: true };
  }

  @Post('payout/thunes')
  @HttpCode(200)
  async thunesPayout(@Body() payload: { external_id?: string; status?: string }) {
    const transferId = payload.external_id;
    if (!transferId) return { ok: true };
    const mapped =
      payload.status === 'COMPLETED' ? 'payout_complete' :
      payload.status === 'CONFIRMED' ? 'payout_pending' :
      payload.status === 'CANCELLED' || payload.status === 'REJECTED' ? 'failed' : null;
    if (mapped) await this.transitionTransfer(transferId, mapped, 'webhook:thunes', payload);
    return { ok: true };
  }

  @Post('kyc/sumsub')
  @HttpCode(200)
  async kycSumsub(
    @Headers('x-payload-digest') signature: string,
    @Req() req: RawBodyRequest<Request>,
  ) {
    const raw = req.rawBody?.toString('utf8');
    if (!raw || !signature || !this.sumsub.verifyWebhook(raw, signature)) {
      throw new BadRequestException('Invalid Sumsub signature.');
    }
    const payload = JSON.parse(raw) as { applicantId?: string; reviewResult?: { reviewAnswer?: string } };
    if (!payload.applicantId) return { ok: true };

    const session = await this.prisma.kycSession.findFirst({
      where: { providerSessionId: payload.applicantId },
    });
    if (!session) return { ok: true };

    const status = payload.reviewResult?.reviewAnswer === 'GREEN' ? 'approved' : 'rejected';
    await this.prisma.$transaction([
      this.prisma.kycSession.update({ where: { id: session.id }, data: { status } }),
      this.prisma.user.update({ where: { id: session.userId }, data: { kycStatus: status } }),
    ]);
    return { ok: true };
  }

  private async transitionTransfer(
    transferId: string,
    toStatus: any,
    source: string,
    metadata: unknown,
  ) {
    const transfer = await this.prisma.transfer.findUnique({ where: { id: transferId } });
    if (!transfer) return;
    const fromStatus = transfer.status;
    if (fromStatus === toStatus) return;
    await this.prisma.$transaction([
      this.prisma.transfer.update({ where: { id: transferId }, data: { status: toStatus } }),
      this.prisma.transferEvent.create({
        data: { transferId, fromStatus, toStatus, source, metadata: metadata as object },
      }),
    ]);
  }
}
