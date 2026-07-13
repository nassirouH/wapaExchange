import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';

const ALLOWED_FIELDS = ['fullName', 'phone', 'addressLine1', 'city', 'postalCode', 'country'] as const;

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async me(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException();
    return user;
  }

  async update(id: string, raw: Record<string, unknown>) {
    const data: Record<string, unknown> = {};
    for (const f of ALLOWED_FIELDS) {
      const snake = f.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);
      if (raw[snake] !== undefined) data[f] = raw[snake];
    }
    return this.prisma.user.update({ where: { id }, data });
  }

  async softDelete(id: string) {
    // Keep AML-relevant data; mark account deleted.
    await this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
    return { ok: true };
  }
}
