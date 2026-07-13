import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';

interface QuoteInput {
  send_currency: string;
  send_amount: number;
  destination_country: string;
  payout_method: 'mobile_money' | 'bank_transfer';
}

const CURRENCY_BY_COUNTRY: Record<string, string> = {
  SN: 'XOF', CI: 'XOF', ML: 'XOF',
  CM: 'XAF',
  NG: 'NGN', KE: 'KES', GH: 'GHS',
  PH: 'PHP', BD: 'BDT', IN: 'INR',
};

// Static mock rates — replace with a real FX feed (OpenExchangeRates, Wise) + Redis cache.
const MID_RATES: Record<string, number> = {
  XOF: 655.96, XAF: 655.96,
  NGN: 1620.5, KES: 138.2, GHS: 16.8,
  PHP: 62.4, BDT: 130.1, INR: 91.2,
};

@Injectable()
export class QuotesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, input: QuoteInput) {
    const receiveCurrency = CURRENCY_BY_COUNTRY[input.destination_country];
    const mid = MID_RATES[receiveCurrency];
    if (!receiveCurrency || !mid) {
      throw new BadRequestException(`Unsupported corridor: ${input.destination_country}`);
    }

    const marginBps = 100; // 1.00% FX markup
    const rate = mid * (1 - marginBps / 10_000);
    const fee = input.send_amount < 100 ? 0.99 : input.send_amount <= 500 ? 1.99 : 3.99;
    const receive = Math.round(input.send_amount * rate * 100) / 100;
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    const quote = await this.prisma.quote.create({
      data: {
        userId,
        sendCurrency: input.send_currency,
        sendAmount: input.send_amount,
        receiveCurrency,
        receiveAmount: receive,
        fxRate: rate,
        fxMarginBps: marginBps,
        feeAmount: fee,
        totalPay: input.send_amount + fee,
        payoutMethod: input.payout_method,
        destinationCountry: input.destination_country,
        expiresAt,
      },
    });

    return {
      id: quote.id,
      send_currency: quote.sendCurrency,
      send_amount: quote.sendAmount,
      receive_currency: quote.receiveCurrency,
      receive_amount: quote.receiveAmount,
      fx_rate: quote.fxRate,
      fee_amount: quote.feeAmount,
      total_pay: quote.totalPay,
      payout_method: quote.payoutMethod,
      destination_country: quote.destinationCountry,
      expires_at: quote.expiresAt,
    };
  }
}
