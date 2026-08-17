import { Controller, Get } from '@nestjs/common';
import { Public } from './common/decorators/public.decorator';
import { PrismaService } from './common/prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Sonda de vida. La app la usa para decidir si intenta sincronizar o se queda
   * en modo offline (HU-07, Sprint 3).
   */
  @Public()
  @Get()
  async estado(): Promise<{ estado: string; db: string; hora: string }> {
    let db = 'ok';

    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      db = 'error';
    }

    return { estado: 'ok', db, hora: new Date().toISOString() };
  }
}
