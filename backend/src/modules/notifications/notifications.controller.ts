import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { IsString } from 'class-validator';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

class RegisterDeviceDto {
  @IsString() apns_token!: string;
  @IsString() device_model!: string;
  @IsString() os_version!: string;
  @IsString() app_version!: string;
}

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('device')
  registerDevice(@Body() dto: RegisterDeviceDto, @Req() req: AuthedRequest) {
    return this.notifications.registerDevice(req.user.id, dto);
  }

  @Get()
  inbox(@Req() req: AuthedRequest) {
    return this.notifications.inbox(req.user.id);
  }

  @Patch(':id/read')
  markRead(@Param('id', ParseUUIDPipe) id: string, @Req() req: AuthedRequest) {
    return this.notifications.markRead(req.user.id, id);
  }
}
