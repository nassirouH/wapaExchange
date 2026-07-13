import { Global, Module } from '@nestjs/common';
import { SumsubClient } from './sumsub.client';

@Global()
@Module({
  providers: [SumsubClient],
  exports: [SumsubClient],
})
export class SumsubModule {}
