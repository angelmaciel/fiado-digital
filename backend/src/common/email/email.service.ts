import { Injectable, Logger } from '@nestjs/common';

/**
 * Puerto de envío de correo. La app solo depende de esta interfaz, así que
 * cambiar de "imprimir en consola" a Resend, SendGrid o SMTP es escribir una
 * clase nueva y cambiar el `useClass` del módulo. Nada más se entera.
 */
export abstract class EmailService {
  abstract enviarCodigoVerificacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void>;

  abstract enviarCodigoRecuperacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void>;
}

/**
 * Implementación de desarrollo: escribe el código en el log del backend en vez
 * de mandarlo por correo. Permite probar el flujo completo sin dar de alta un
 * proveedor ni verificar un dominio.
 */
@Injectable()
export class EmailConsolaService extends EmailService {
  private readonly logger = new Logger('Email');

  async enviarCodigoVerificacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void> {
    this.imprimir('VERIFICACIÓN DE CORREO', destinatario, nombre, codigo);
  }

  async enviarCodigoRecuperacion(
    destinatario: string,
    nombre: string,
    codigo: string,
  ): Promise<void> {
    this.imprimir('RECUPERACIÓN DE CONTRASEÑA', destinatario, nombre, codigo);
  }

  private imprimir(asunto: string, destinatario: string, nombre: string, codigo: string) {
    this.logger.warn(
      [
        '',
        '='.repeat(56),
        `  ${asunto}`,
        `  Para: ${nombre} <${destinatario}>`,
        `  Código: ${codigo}`,
        '  Vence en 10 minutos.',
        '='.repeat(56),
      ].join('\n'),
    );
  }
}
