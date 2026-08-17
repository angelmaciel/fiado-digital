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

    if (status === HttpStatus.INTERNAL_SERVER_ERROR) {
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
      default:
        return {
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          mensaje: 'Error inesperado al acceder a la base de datos',
        };
    }
  }
}
