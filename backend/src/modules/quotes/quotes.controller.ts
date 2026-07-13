import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsISO31661Alpha2, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { JwtAuthGuard, AuthedRequest } from '../../common/guards/jwt-auth.guard';
import { QuotesService } from './quotes.service';

class QuoteDto {
  @IsIn(['EUR'])
  send_currency!: string;

  @Type(() => Number)
  @IsNumber()
  @Min(1)
  send_amount!: number;

  @IsISO31661Alpha2()
  destination_country!: string;

  @IsIn(['mobile_money', 'bank_transfer'])
  payout_method!: 'mobile_money' | 'bank_transfer';
}

@UseGuards(JwtAuthGuard)
@Controller('quotes')
export class QuotesController {
  constructor(private readonly quotes: QuotesService) {}

  @Post()
  create(@Body() dto: QuoteDto, @Req() req: AuthedRequest) {
    return this.quotes.create(req.user.id, dto);
  }
}
