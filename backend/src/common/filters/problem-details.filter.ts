import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  detail?: string;
  instance: string;
  errors?: unknown;
}

const BASE = 'https://wapaexchange.com/errors';

const TYPE_BY_STATUS: Record<number, { type: string; title: string }> = {
  400: { type: `${BASE}/bad-request`, title: 'Bad Request' },
  401: { type: `${BASE}/unauthorized`, title: 'Unauthorized' },
  403: { type: `${BASE}/forbidden`, title: 'Forbidden' },
  404: { type: `${BASE}/not-found`, title: 'Not Found' },
  409: { type: `${BASE}/conflict`, title: 'Conflict' },
  410: { type: `${BASE}/gone`, title: 'Gone' },
  422: { type: `${BASE}/unprocessable-entity`, title: 'Unprocessable Entity' },
  429: { type: `${BASE}/too-many-requests`, title: 'Too Many Requests' },
  500: { type: `${BASE}/internal-server-error`, title: 'Internal Server Error' },
  503: { type: `${BASE}/service-unavailable`, title: 'Service Unavailable' },
};

/**
 * Returns errors as RFC 7807 `application/problem+json` documents.
 * Hides internal stack traces from clients in production while logging them.
 */
@Catch()
export class ProblemDetailsFilter implements ExceptionFilter {
  private readonly logger = new Logger(ProblemDetailsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const mapping = TYPE_BY_STATUS[status] ?? {
      type: `${BASE}/internal-server-error`,
      title: 'Internal Server Error',
    };

    let detail: string | undefined;
    let errors: unknown;
    if (exception instanceof HttpException) {
      const body = exception.getResponse();
      if (typeof body === 'string') {
        detail = body;
      } else if (body && typeof body === 'object') {
        const obj = body as Record<string, unknown>;
        detail = typeof obj.message === 'string'
          ? obj.message
          : Array.isArray(obj.message) ? obj.message.join('; ') : undefined;
        // class-validator surfaces validation issues under `message` as an array.
        if (Array.isArray(obj.message)) errors = obj.message;
      }
    } else if (exception instanceof Error) {
      this.logger.error(exception.message, exception.stack);
      detail = process.env.NODE_ENV === 'production' ? undefined : exception.message;
    }

    const problem: ProblemDetails = {
      type: mapping.type,
      title: mapping.title,
      status,
      detail,
      instance: req.originalUrl,
      ...(errors ? { errors } : {}),
    };

    res
      .status(status)
      .setHeader('Content-Type', 'application/problem+json')
      .json(problem);
  }
}
