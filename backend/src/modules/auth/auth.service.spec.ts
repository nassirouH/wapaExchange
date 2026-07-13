import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { AuthService } from './auth.service';

/**
 * In-memory Prisma test double — enough surface area for AuthService.
 */
function makePrismaMock() {
  const users = new Map<string, { id: string; email: string; passwordHash: string; fullName: string; authProvider: string }>();
  const refreshTokens: Array<{
    id: string;
    userId: string;
    tokenHash: string;
    expiresAt: Date;
    revokedAt: Date | null;
  }> = [];
  let userIdSeq = 0;
  let tokenIdSeq = 0;

  return {
    user: {
      findUnique: jest.fn(async ({ where }: { where: { email?: string; id?: string } }) => {
        for (const u of users.values()) {
          if (where.email && u.email === where.email) return u;
          if (where.id && u.id === where.id) return u;
        }
        return null;
      }),
      create: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        const u = {
          id: `user_${++userIdSeq}`,
          email: data.email as string,
          passwordHash: data.passwordHash as string,
          fullName: data.fullName as string,
          authProvider: (data.authProvider as string) ?? 'email',
        };
        users.set(u.id, u);
        return u;
      }),
    },
    refreshToken: {
      findFirst: jest.fn(async ({ where }: { where: { tokenHash: string; revokedAt: null } }) => {
        const t = refreshTokens.find((r) => r.tokenHash === where.tokenHash && r.revokedAt === null);
        if (!t) return null;
        const u = users.get(t.userId)!;
        return { ...t, user: u };
      }),
      create: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        const t = {
          id: `rt_${++tokenIdSeq}`,
          userId: data.userId as string,
          tokenHash: data.tokenHash as string,
          expiresAt: data.expiresAt as Date,
          revokedAt: null,
        };
        refreshTokens.push(t);
        return t;
      }),
      update: jest.fn(async ({ where, data }: { where: { id: string }; data: { revokedAt: Date } }) => {
        const t = refreshTokens.find((r) => r.id === where.id);
        if (t) t.revokedAt = data.revokedAt;
        return t;
      }),
      updateMany: jest.fn(async ({ where, data }: { where: { tokenHash: string; revokedAt: null }; data: { revokedAt: Date } }) => {
        let count = 0;
        for (const t of refreshTokens) {
          if (t.tokenHash === where.tokenHash && t.revokedAt === null) {
            t.revokedAt = data.revokedAt;
            count++;
          }
        }
        return { count };
      }),
    },
    _internals: { users, refreshTokens },
  };
}

describe('AuthService', () => {
  let service: AuthService;
  let prisma: ReturnType<typeof makePrismaMock>;
  let jwt: JwtService;

  beforeAll(() => {
    process.env.JWT_ACCESS_SECRET = 'test-secret';
    process.env.JWT_REFRESH_TTL = '60';
  });

  beforeEach(() => {
    prisma = makePrismaMock();
    jwt = new JwtService({ secret: 'test-secret', signOptions: { expiresIn: '1m' } });
    service = new AuthService(prisma as never, jwt);
  });

  describe('register', () => {
    it('hashes the password with argon2id and persists the user', async () => {
      const result = await service.register('alice@example.com', 'secret123', 'Alice');
      expect(result.access_token).toBeTruthy();
      expect(result.refresh_token).toBeTruthy();
      const saved = prisma._internals.users.get('user_1')!;
      expect(saved.passwordHash).toMatch(/^\$argon2id\$/);
      const matches = await argon2.verify(saved.passwordHash, 'secret123');
      expect(matches).toBe(true);
    });

    it('strips passwordHash from the response', async () => {
      const result = await service.register('alice@example.com', 'secret123', 'Alice');
      expect((result.user as Record<string, unknown>).passwordHash).toBeUndefined();
    });

    it('rejects duplicate emails with 409', async () => {
      await service.register('alice@example.com', 'secret123', 'Alice');
      await expect(
        service.register('alice@example.com', 'other_pw', 'Alice Two'),
      ).rejects.toBeInstanceOf(ConflictException);
    });
  });

  describe('login', () => {
    it('verifies the password against the argon2 hash', async () => {
      await service.register('alice@example.com', 'secret123', 'Alice');
      const result = await service.login('alice@example.com', 'secret123');
      expect(result.access_token).toBeTruthy();
    });

    it('rejects wrong passwords with 401', async () => {
      await service.register('alice@example.com', 'secret123', 'Alice');
      await expect(service.login('alice@example.com', 'WRONG')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects unknown emails with 401 (no user enumeration)', async () => {
      await expect(service.login('ghost@example.com', 'secret123')).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    it('rotates the refresh token: old one is revoked, new one issued', async () => {
      const first = await service.register('alice@example.com', 'secret123', 'Alice');
      const second = await service.refresh(first.refresh_token);
      expect(second.refresh_token).not.toBe(first.refresh_token);
      // First refresh token should now be revoked; re-using it must fail.
      await expect(service.refresh(first.refresh_token)).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('logout', () => {
    it('revokes the supplied refresh token so subsequent refresh fails', async () => {
      const { refresh_token } = await service.register('alice@example.com', 'secret123', 'Alice');
      await service.logout(refresh_token);
      await expect(service.refresh(refresh_token)).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });
});
