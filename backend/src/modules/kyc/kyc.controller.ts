import { Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { KycService } from './kyc.service';

@UseGuards(JwtAuthGuard)
@Controller('kyc')
export class KycController {
  constructor(private readonly kyc: KycService) {}

  @Post('session')
  startSession(@Req() req: AuthedRequest) {
    return this.kyc.startSession(req.user.id);
  }

  @Get('status')
  status(@Req() req: AuthedRequest) {
    return this.kyc.status(req.user.id);
  }
}
