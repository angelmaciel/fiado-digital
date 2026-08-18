import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, type Transporter } from 'nodemailer';
import { EmailService } from './email.service';

/**
 * Envío real por SMTP.
 *
 * Se eligió SMTP y no el SDK de un proveedor concreto porque así la misma clase
 * sirve para Gmail, Brevo, Mailtrap o el SMTP de Resend: cambian las variables
 * de entorno, no el código. Para un proyecto que todavía no sabe con qué
 * proveedor va a terminar, es la opción que menos compromete.
 */
@Injectable()
export class EmailSmtpService extends EmailService implements OnModuleInit {
  private readonly logger = new Logger('EmailSmtp');
  private readonly transporte: Transporter;
  private readonly remitente: string;

  constructor(private readonly config: ConfigService) {
    super();

    const host = this.config.getOrThrow<string>('SMTP_HOST');
    const puerto = Number(this.config.get('SMTP_PORT', 587));

    this.transporte = createTransport({
      host,
      port: puerto,
      // El 465 habla TLS desde el saludo inicial; el 587 arranca en claro y
      // sube a TLS con STARTTLS. Confundirlos es el error más común al
      // configurar SMTP y deja el envío colgado sin mensaje claro.
      secure: puerto === 465,
      auth: {
        user: this.config.getOrThrow<string>('SMTP_USER'),
        pass: this.config.getOrThrow<string>('SMTP_PASSWORD'),
      },
    });

    this.remitente = this.config.get<string>(
      'EMAIL_REMITENTE',
      `Fiado Digital <${this.config.get('SMTP_USER')}>`,
    );
  }

  /**
   * Se comprueba la conexión al arrancar, no al mandar el primer correo.
   *
   * Si las credenciales están mal, es mucho mejor enterarse levantando el
   * servidor que cuando un despensero se está registrando y su código nunca
   * llega.
   */
  async onModuleInit(): Promise<void> {
    try {
      await this.transporte.verify();
      this.logger.log('Conexión SMTP verificada');
    } catch (error) {
      this.logger.error(
        `No se pudo conectar al servidor SMTP: ${(error as Error).message}`,
      );
      this.logger.warn(
        'Los correos no se van a enviar. Revisá las variables SMTP_* del .env.',
      );
    }
  }

  async enviarCodigoVerificacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void> {
    await this.enviar({
      destinatario,
      asunto: `${codigo} es tu código de Fiado Digital`,
      titulo: `Hola ${nombre}`,
      bajada: 'Usá este código para confirmar tu correo:',
      codigo,
      cierre:
        'Si no fuiste vos quien creó la cuenta, podés ignorar este mensaje.',
    });
  }

  async enviarCodigoRecuperacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void> {
    await this.enviar({
      destinatario,
      asunto: `${codigo} es tu código para cambiar la contraseña`,
      titulo: `Hola ${nombre}`,
      bajada: 'Usá este código para poner una contraseña nueva:',
      codigo,
      cierre:
        'Si no pediste cambiarla, ignorá este mensaje: tu contraseña sigue ' +
        'siendo la misma.',
    });
  }

  private async enviar(datos: {
    destinatario: string;
    asunto: string;
    titulo: string;
    bajada: string;
    codigo: string;
    cierre: string;
  }): Promise<void> {
    try {
      await this.transporte.sendMail({
        from: this.remitente,
        to: datos.destinatario,
        subject: datos.asunto,
        // Se manda texto plano además del HTML: hay clientes que no muestran
        // HTML, y un correo que solo trae HTML puntúa peor en los filtros de
        // spam.
        text: `${datos.titulo}\n\n${datos.bajada}\n\n${datos.codigo}\n\n` +
          `El código vence en 10 minutos.\n\n${datos.cierre}`,
        html: this.plantilla(datos),
      });

      this.logger.log(`Código enviado a ${datos.destinatario}`);
    } catch (error) {
      this.logger.error(
        `No se pudo enviar el correo a ${datos.destinatario}: ${(error as Error).message}`,
      );
      // Se relanza para que el usuario reciba un error y pueda reintentar, en
      // vez de quedarse esperando un código que nunca salió.
      throw error;
    }
  }

  /**
   * Estilos en línea y estructura simple a propósito: los clientes de correo
   * ignoran las hojas de estilo y muchos rompen los diseños con flexbox.
   */
  private plantilla(datos: {
    titulo: string;
    bajada: string;
    codigo: string;
    cierre: string;
  }): string {
    return `<!doctype html>
<html lang="es">
  <body style="margin:0;padding:24px;background:#f4f4f5;font-family:system-ui,-apple-system,Segoe UI,sans-serif;color:#18181b;">
    <div style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:12px;padding:32px;">
      <p style="margin:0 0 4px;font-size:14px;color:#00695c;font-weight:600;">Fiado Digital</p>
      <h1 style="margin:0 0 16px;font-size:20px;">${datos.titulo}</h1>
      <p style="margin:0 0 24px;font-size:15px;line-height:1.5;">${datos.bajada}</p>
      <p style="margin:0 0 24px;font-size:34px;font-weight:700;letter-spacing:8px;text-align:center;background:#f4f4f5;border-radius:8px;padding:16px;">
        ${datos.codigo}
      </p>
      <p style="margin:0 0 24px;font-size:13px;color:#71717a;">El código vence en 10 minutos.</p>
      <p style="margin:0;font-size:13px;color:#71717a;line-height:1.5;">${datos.cierre}</p>
    </div>
  </body>
</html>`;
  }
}
