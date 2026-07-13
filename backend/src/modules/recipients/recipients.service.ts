import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';

@Injectable()
export class RecipientsService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.recipient.findMany({
      where: { userId, deletedAt: null },
      orderBy: [{ isFavorite: 'desc' }, { lastUsedAt: 'desc' }],
    });
  }

  create(userId: string, dto: Record<string, any>) {
    return this.prisma.recipient.create({
      data: {
        userId,
        fullName: dto.full_name,
        country: dto.country,
        payoutMethod: dto.payout_method,
        mobileMoneyProvider: dto.mobile_money_provider ?? null,
        mobileMoneyNumber: dto.mobile_money_number ?? null,
        bankName: dto.bank_name ?? null,
        bankAccountNumber: dto.bank_account_number ?? null,
      },
    });
  }

  async update(userId: string, id: string, dto: Record<string, any>) {
    await this.ensureOwned(userId, id);
    return this.prisma.recipient.update({
      where: { id },
      data: {
        fullName: dto.full_name,
        mobileMoneyProvider: dto.mobile_money_provider,
        mobileMoneyNumber: dto.mobile_money_number,
        bankName: dto.bank_name,
        bankAccountNumber: dto.bank_account_number,
      },
    });
  }

  async softDelete(userId: string, id: string) {
    await this.ensureOwned(userId, id);
    await this.prisma.recipient.update({ where: { id }, data: { deletedAt: new Date() } });
    return { ok: true };
  }

  async toggleFavorite(userId: string, id: string) {
    const r = await this.ensureOwned(userId, id);
    return this.prisma.recipient.update({
      where: { id },
      data: { isFavorite: !r.isFavorite },
    });
  }

  private async ensureOwned(userId: string, id: string) {
    const r = await this.prisma.recipient.findFirst({ where: { id, userId, deletedAt: null } });
    if (!r) throw new NotFoundException();
    return r;
  }
}
