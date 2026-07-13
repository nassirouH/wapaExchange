import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ComplianceService } from './compliance.service';
import { SanctionsService } from './sanctions.service';
import { RulesEngine } from './rules.engine';
import { ComplianceController } from './compliance.controller';

@Global()
@Module({
  imports: [JwtModule.register({ secret: process.env.JWT_ACCESS_SECRET })],
  providers: [ComplianceService, SanctionsService, RulesEngine],
  controllers: [ComplianceController],
  exports: [ComplianceService, SanctionsService],
})
export class ComplianceModule {}
