import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { SumsubClient } from '../../integrations/sumsub/sumsub.client';

@Injectable()
export class KycService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sumsub: SumsubClient,
  ) {}

  async startSession(userId: string) {
    // Reuse an existing applicant if one already exists for this user.
    let session = await this.prisma.kycSession.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    if (!session || session.status === 'rejected') {
      const applicant = await this.sumsub.createApplicant(userId);
      session = await this.prisma.kycSession.create({
        data: {
          userId,
          provider: 'sumsub',
          providerSessionId: applicant.id,
          status: 'pending',
        },
      });
    }

    const sdk = await this.sumsub.generateSdkToken(session.providerSessionId, userId);

    return {
      id: session.id,
      provider: 'sumsub',
      provider_session_id: session.providerSessionId,
      sdk_token: sdk.token,
      status: session.status,
      expires_at: new Date(Date.now() + 30 * 60 * 1000),
    };
  }

  async status(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { kycStatus: true },
    });
    return { kyc_status: user.kycStatus };
  }
}
