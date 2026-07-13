import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { RecipientsController } from './recipients.controller';
import { RecipientsService } from './recipients.service';
import { PrismaModule } from '../../infra/prisma/prisma.module';

@Module({
  imports: [PrismaModule, JwtModule.register({ secret: process.env.JWT_ACCESS_SECRET })],
  controllers: [RecipientsController],
  providers: [RecipientsService],
})
export class RecipientsModule {}
