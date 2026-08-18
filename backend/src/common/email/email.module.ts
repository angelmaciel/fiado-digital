import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailSmtpService } from './email-smtp.service';
import { EmailConsolaService, EmailService } from './email.service';

/**
 * Qué implementación se usa lo decide `EMAIL_PROVIDER` del `.env`:
 *
 *   consola  imprime el código en el log (por defecto)
 *   smtp     lo manda de verdad
 *
 * El default es la consola a propósito: alguien que clona el repo y levanta el
 * proyecto puede registrarse y probar todo sin dar de alta ningún proveedor.
 */
@Global()
@Module({
  providers: [
    {
      provide: EmailService,
      inject: [ConfigService],
      useFactory: (config: ConfigService): EmailService => {
        const proveedor = config.get<string>('EMAIL_PROVIDER', 'consola');

        return proveedor === 'smtp'
          ? new EmailSmtpService(config)
          : new EmailConsolaService();
      },
    },
  ],
  exports: [EmailService],
})
export class EmailModule {}
