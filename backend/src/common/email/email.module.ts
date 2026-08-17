import { Global, Module } from '@nestjs/common';
import { EmailConsolaService, EmailService } from './email.service';

/**
 * Para pasar a un proveedor real (Resend, SendGrid, SMTP) alcanza con escribir
 * la clase que implemente `EmailService` y cambiar el `useClass` de acá.
 */
@Global()
@Module({
  providers: [{ provide: EmailService, useClass: EmailConsolaService }],
  exports: [EmailService],
})
export class EmailModule {}
