import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { ClientesModule } from './clientes/clientes.module';
import { validarEntorno } from './common/config/env.validation';
import { EmailModule } from './common/email/email.module';
import { PrismaExceptionFilter } from './common/filters/prisma-exception.filter';
import { PrismaModule } from './common/prisma/prisma.module';
import { DespensasModule } from './despensas/despensas.module';
import { HealthController } from './health.controller';
import { UsuariosModule } from './usuarios/usuarios.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: validarEntorno,
    }),
    PrismaModule,
    EmailModule,
    AuthModule,
    UsuariosModule,
    DespensasModule,
    ClientesModule,
    // Sprint 2: MovimientosModule (HU-03, HU-04, HU-05)
    // Sprint 4: MetodosPagoModule (HU-11, HU-12)
  ],
  controllers: [HealthController],
  providers: [
    // Cerrado por defecto: sin @Public(), todo endpoint exige Bearer token.
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_FILTER, useClass: PrismaExceptionFilter },
  ],
})
export class AppModule {}
