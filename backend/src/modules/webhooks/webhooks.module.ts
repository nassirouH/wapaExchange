import { Module } from '@nestjs/common';
import { WebhooksController } from './webhooks.controller';
import { TransfersModule } from '../transfers/transfers.module';

@Module({
  imports: [TransfersModule], // for TransfersService.enqueuePayout
  controllers: [WebhooksController],
})
export class WebhooksModule {}
