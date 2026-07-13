import { Body, Controller, Delete, Get, Patch, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { UsersService } from './users.service';

@UseGuards(JwtAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  me(@Req() req: AuthedRequest) {
    return this.users.me(req.user.id);
  }

  @Patch()
  update(@Req() req: AuthedRequest, @Body() patch: Record<string, unknown>) {
    return this.users.update(req.user.id, patch);
  }

  @Delete()
  remove(@Req() req: AuthedRequest) {
    return this.users.softDelete(req.user.id);
  }
}
