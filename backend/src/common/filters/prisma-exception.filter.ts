import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { Response } from 'express';

/**
 * Traduce los errores conocidos de Prisma a respuestas HTTP con sentido, en vez
 * de dejar que se conviertan en un 500 opaco con el mensaje interno de la DB.
 */
@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(exception: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();

    const { status, mensaje } = this.traducir(exception);

    // Se registra todo lo que no sea un 4xx esperable: un 500 o un 503 siempre
    // merecen quedar en el log con su código de Prisma, que es lo único que
    // permite diagnosticar después.
    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(`Prisma ${exception.code}: ${exception.message}`);
    }

    response.status(status).json({
      statusCode: status,
      message: mensaje,
      error: HttpStatus[status],
    });
  }

  private traducir(e: Prisma.PrismaClientKnownRequestError): {
    status: number;
    mensaje: string;
  } {
    switch (e.code) {
      case 'P2002': {
        const campos = (e.meta?.target as string[] | undefined)?.join(', ') ?? 'un campo único';
        return {
          status: HttpStatus.CONFLICT,
          mensaje: `Ya existe un registro con ese valor en: ${campos}`,
        };
      }
      case 'P2003':
        return {
          status: HttpStatus.BAD_REQUEST,
          mensaje: 'La referencia indicada no existe',
        };
      case 'P2025':
        return {
          status: HttpStatus.NOT_FOUND,
          mensaje: 'El registro solicitado no existe',
        };
      case 'P2024':
        // Pool de conexiones agotado. Se responde 503 y no 500 porque es
        // transitorio: reintentar tiene sentido. Un 500 haría que la app lo
        // tratara como un error de programación y no lo reintentara.
        return {
          status: HttpStatus.SERVICE_UNAVAILABLE,
          mensaje: 'El servidor está saturado. Probá de nuevo en unos segundos.',
        };
      case 'P1001':
      case 'P1002':
        return {
          status: HttpStatus.SERVICE_UNAVAILABLE,
          mensaje: 'No se pudo conectar con la base de datos. Reintentá en unos segundos.',
        };
      default:
        return {
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          mensaje: 'Error inesperado al acceder a la base de datos',
        };
    }
  }
}
