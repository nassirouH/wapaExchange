import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { IsIn, IsISO31661Alpha2, IsOptional, IsString, MinLength } from 'class-validator';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { RecipientsService } from './recipients.service';

class CreateRecipientDto {
  @IsString() @MinLength(2) full_name!: string;
  @IsISO31661Alpha2() country!: string;
  @IsIn(['mobile_money', 'bank_transfer']) payout_method!: 'mobile_money' | 'bank_transfer';
  @IsOptional() @IsString() mobile_money_provider?: string;
  @IsOptional() @IsString() mobile_money_number?: string;
  @IsOptional() @IsString() bank_name?: string;
  @IsOptional() @IsString() bank_account_number?: string;
}

@UseGuards(JwtAuthGuard)
@Controller('recipients')
export class RecipientsController {
  constructor(private readonly recipients: RecipientsService) {}

  @Get()
  list(@Req() req: AuthedRequest) {
    return this.recipients.list(req.user.id);
  }

  @Post()
  create(@Body() dto: CreateRecipientDto, @Req() req: AuthedRequest) {
    return this.recipients.create(req.user.id, dto);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: Partial<CreateRecipientDto>,
    @Req() req: AuthedRequest,
  ) {
    return this.recipients.update(req.user.id, id, dto);
  }

  @Delete(':id')
  remove(@Param('id', ParseUUIDPipe) id: string, @Req() req: AuthedRequest) {
    return this.recipients.softDelete(req.user.id, id);
  }

  @Post(':id/favorite')
  toggleFavorite(@Param('id', ParseUUIDPipe) id: string, @Req() req: AuthedRequest) {
    return this.recipients.toggleFavorite(req.user.id, id);
  }
}
