import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { PrismaService } from '../../infra/prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(email: string, password: string, fullName: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email already in use.');
    const passwordHash = await argon2.hash(password);
    const user = await this.prisma.user.create({
      data: { email, passwordHash, fullName, authProvider: 'email' },
    });
    return this.issueTokens(user.id, user.email, user);
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials.');
    const ok = await argon2.verify(user.passwordHash, password);
    if (!ok) throw new UnauthorizedException('Invalid credentials.');
    return this.issueTokens(user.id, user.email, user);
  }

  async refresh(refreshToken: string) {
    const tokenHash = this.hash(refreshToken);
    const record = await this.prisma.refreshToken.findFirst({
      where: { tokenHash, revokedAt: null, expiresAt: { gt: new Date() } },
      include: { user: true },
    });
    if (!record) throw new UnauthorizedException('Invalid refresh token.');
    await this.prisma.refreshToken.update({
      where: { id: record.id },
      data: { revokedAt: new Date() },
    });
    return this.issueTokens(record.user.id, record.user.email, record.user);
  }

  async logout(refreshToken: string) {
    const tokenHash = this.hash(refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  private async issueTokens(userId: string, email: string, user: unknown) {
    const accessToken = await this.jwt.signAsync({ sub: userId, email });
    const refreshToken = crypto.randomBytes(48).toString('base64url');
    const expiresAt = new Date(
      Date.now() + Number(process.env.JWT_REFRESH_TTL ?? 2_592_000) * 1000,
    );
    await this.prisma.refreshToken.create({
      data: { userId, tokenHash: this.hash(refreshToken), expiresAt },
    });
    return { access_token: accessToken, refresh_token: refreshToken, user };
  }

  private hash(token: string) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
