import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

const isWorker = process.argv.includes('--worker') || process.env.ROLE === 'worker';
// Set ROLE before importing AppModule so QueueModule sees it at module-load time.
if (isWorker) process.env.ROLE = 'worker';

import { AppModule } from './app.module';

async function bootstrapApi() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log'],
    rawBody: true, // required so /webhooks endpoints can verify HMAC signatures
  });

  app.setGlobalPrefix('v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.enableCors({
    origin: process.env.CORS_ORIGIN?.split(',') ?? '*',
    credentials: true,
  });

  const config = new DocumentBuilder()
    .setTitle('wapaExchange API')
    .setDescription('Remittance orchestration API for Europe → Africa & Asia')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('v1/docs', app, document);

  const port = Number(process.env.PORT) || 3000;
  await app.listen(port);
  Logger.log(`API listening on http://localhost:${port}/v1`, 'Bootstrap');
}

async function bootstrapWorker() {
  // Worker mode: no HTTP listener. NestApplicationContext starts the providers
  // (including the BullMQ Worker registered by QueueModule when ROLE=worker)
  // and keeps the process alive until SIGTERM.
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  Logger.log('Worker started — listening on BullMQ payouts queue.', 'Bootstrap');

  const shutdown = async (signal: string) => {
    Logger.log(`Received ${signal} — shutting down worker.`, 'Bootstrap');
    await app.close();
    process.exit(0);
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

(isWorker ? bootstrapWorker() : bootstrapApi()).catch((err) => {
  Logger.error(err, 'Bootstrap');
  process.exit(1);
});
