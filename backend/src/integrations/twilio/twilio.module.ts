import { Global, Module } from '@nestjs/common';
import { TwilioClient } from './twilio.client';

@Global()
@Module({
  providers: [TwilioClient],
  exports: [TwilioClient],
})
export class TwilioModule {}
