import { Global, Module } from '@nestjs/common';
import { ThunesClient } from './thunes.client';

@Global()
@Module({
  providers: [ThunesClient],
  exports: [ThunesClient],
})
export class ThunesModule {}
