import { Body, Controller, Get, Param, ParseUUIDPipe, Post, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsUUID } from 'class-validator';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { TransfersService } from './transfers.service';

class CreateTransferDto {
  @IsUUID() quote_id!: string;
  @IsUUID() recipient_id!: string;
  @IsIn(['apple_pay', 'card', 'sepa', 'open_banking'])
  payin_method!: 'apple_pay' | 'card' | 'sepa' | 'open_banking';
}

@UseGuards(JwtAuthGuard)
@Controller('transfers')
export class TransfersController {
  constructor(private readonly transfers: TransfersService) {}

  @Post()
  create(@Body() dto: CreateTransferDto, @Req() req: AuthedRequest) {
    return this.transfers.create(req.user.id, dto);
  }

  @Get()
  list(@Req() req: AuthedRequest) {
    return this.transfers.listForUser(req.user.id);
  }

  @Get(':id')
  detail(@Param('id', ParseUUIDPipe) id: string, @Req() req: AuthedRequest) {
    return this.transfers.detail(req.user.id, id);
  }

  @Post(':id/cancel')
  cancel(@Param('id', ParseUUIDPipe) id: string, @Req() req: AuthedRequest) {
    return this.transfers.cancel(req.user.id, id);
  }
}
