import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsString, MinLength } from 'class-validator';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { ComplianceService } from './compliance.service';

class ReviewDto {
  @IsIn(['cleared', 'escalated']) decision!: 'cleared' | 'escalated';
  @IsString() @MinLength(3) note!: string;
}

/**
 * Admin-only endpoints. Production should layer an `@Roles('compliance_officer')` guard
 * on top of `JwtAuthGuard`. For MVP we expose under /v1/admin/compliance and gate via
 * an ALB rule that requires a private VPN / Cloudflare Access policy.
 */
@UseGuards(JwtAuthGuard)
@Controller('admin/compliance')
export class ComplianceController {
  constructor(private readonly compliance: ComplianceService) {}

  @Get('flags')
  list(@Query('status') status?: 'open' | 'reviewing') {
    return this.compliance.listFlags({ status });
  }

  @Patch('flags/:id')
  review(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewDto,
    @Req() req: AuthedRequest,
  ) {
    return this.compliance.reviewFlag(id, req.user.id, dto.decision, dto.note);
  }
}
