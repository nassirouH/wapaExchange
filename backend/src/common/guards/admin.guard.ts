import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import type { AuthedRequest } from './jwt-auth.guard';

/**
 * Requires the caller's user row to have `is_admin = true`. Combine with
 * `JwtAuthGuard` — apply as `@UseGuards(JwtAuthGuard, AdminGuard)`.
 *
 * Admins are provisioned by directly updating the users table:
 *   UPDATE users SET is_admin = true WHERE email = 'you@wapaexchange.com';
 */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<AuthedRequest>();
    const user = await this.prisma.user.findUnique({
      where: { id: req.user.id },
      select: { isAdmin: true },
    });
    if (!user?.isAdmin) throw new ForbiddenException('Admin access required.');
    return true;
  }
}
