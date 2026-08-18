import { BadRequestException } from '@nestjs/common';
import { TipoCodigo } from '@prisma/client';
import { EmailService } from '../common/email/email.service';
import { PrismaService } from '../common/prisma/prisma.service';
import { CodigosService } from './codigos.service';

/**
 * Un código de 6 dígitos es un secreto muy débil: solo un millón de
 * combinaciones. Lo que realmente lo protege son estas reglas, así que valen
 * la pena probarlas una por una.
 */
describe('CodigosService', () => {
  const USUARIO = 'usuario-1';

  let prisma: {
    codigoVerificacion: {
      findFirst: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
      create: jest.Mock;
    };
    $transaction: jest.Mock;
  };
  let email: { enviarCodigoVerificacion: jest.Mock; enviarCodigoRecuperacion: jest.Mock };
  let service: CodigosService;

  const enUnRato = () => new Date(Date.now() + 5 * 60 * 1000);
  const haceUnRato = () => new Date(Date.now() - 5 * 60 * 1000);

  beforeEach(() => {
    prisma = {
      codigoVerificacion: {
        findFirst: jest.fn(),
        update: jest.fn().mockResolvedValue({}),
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        create: jest.fn().mockResolvedValue({}),
      },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    email = {
      enviarCodigoVerificacion: jest.fn().mockResolvedValue(undefined),
      enviarCodigoRecuperacion: jest.fn().mockResolvedValue(undefined),
    };

    service = new CodigosService(
      prisma as unknown as PrismaService,
      email as unknown as EmailService,
    );
  });

  describe('al emitir', () => {
    const usuario = {
      id: USUARIO,
      email: 'ramona@ejemplo.com',
      nombre: 'Ramona',
    } as never;

    it('genera un código de exactamente 6 dígitos', async () => {
      await service.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);

      const codigo = email.enviarCodigoVerificacion.mock.calls[0][2];
      expect(codigo).toMatch(/^\d{6}$/);
    });

    it('invalida los códigos anteriores del mismo tipo', async () => {
      // Sin esto, tocar "reenviar" tres veces dejaría tres códigos válidos.
      await service.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);

      expect(prisma.codigoVerificacion.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ usedAt: null }),
        }),
      );
    });

    it('nunca guarda el código en claro', async () => {
      await service.emitirYEnviar(usuario, TipoCodigo.VERIFICACION_EMAIL);

      const codigo = email.enviarCodigoVerificacion.mock.calls[0][2];
      const guardado = prisma.codigoVerificacion.create.mock.calls[0][0].data;

      expect(guardado.codigoHash).not.toBe(codigo);
      expect(guardado.codigoHash).toHaveLength(64);
    });

    it('usa el remitente correcto según el tipo', async () => {
      await service.emitirYEnviar(usuario, TipoCodigo.RESET_PASSWORD);

      expect(email.enviarCodigoRecuperacion).toHaveBeenCalled();
      expect(email.enviarCodigoVerificacion).not.toHaveBeenCalled();
    });
  });

  describe('al consumir', () => {
    /** Emite un código y devuelve el par (código en claro, registro guardado). */
    async function emitirYCapturar() {
      await service.emitirYEnviar(
        { id: USUARIO, email: 'a@b.com', nombre: 'Ramona' } as never,
        TipoCodigo.VERIFICACION_EMAIL,
      );

      return {
        codigo: email.enviarCodigoVerificacion.mock.calls[0][2] as string,
        hash: prisma.codigoVerificacion.create.mock.calls[0][0].data.codigoHash,
      };
    }

    it('acepta el código correcto y lo quema', async () => {
      const { codigo, hash } = await emitirYCapturar();
      prisma.codigoVerificacion.findFirst.mockResolvedValue({
        id: 'c1',
        codigoHash: hash,
        expiresAt: enUnRato(),
        intentos: 0,
      });

      await expect(
        service.consumir(USUARIO, TipoCodigo.VERIFICACION_EMAIL, codigo),
      ).resolves.toBeUndefined();

      // Quemarlo es lo que impide reusarlo.
      expect(prisma.codigoVerificacion.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ usedAt: expect.any(Date) }),
        }),
      );
    });

    it('rechaza un código vencido', async () => {
      const { codigo, hash } = await emitirYCapturar();
      prisma.codigoVerificacion.findFirst.mockResolvedValue({
        id: 'c1',
        codigoHash: hash,
        expiresAt: haceUnRato(),
        intentos: 0,
      });

      await expect(
        service.consumir(USUARIO, TipoCodigo.VERIFICACION_EMAIL, codigo),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rechaza un código equivocado y cuenta el intento', async () => {
      const { hash } = await emitirYCapturar();
      prisma.codigoVerificacion.findFirst.mockResolvedValue({
        id: 'c1',
        codigoHash: hash,
        expiresAt: enUnRato(),
        intentos: 1,
      });

      await expect(
        service.consumir(USUARIO, TipoCodigo.VERIFICACION_EMAIL, '000000'),
      ).rejects.toBeInstanceOf(BadRequestException);

      expect(prisma.codigoVerificacion.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ intentos: 2 }),
        }),
      );
    });

    it('quema el código al llegar al límite de intentos', async () => {
      // Es la defensa real contra la fuerza bruta: sin ella, un millón de
      // combinaciones se agotan en minutos.
      prisma.codigoVerificacion.findFirst.mockResolvedValue({
        id: 'c1',
        codigoHash: 'a'.repeat(64),
        expiresAt: enUnRato(),
        intentos: 5,
      });

      await expect(
        service.consumir(USUARIO, TipoCodigo.VERIFICACION_EMAIL, '123456'),
      ).rejects.toThrow(/Demasiados intentos/);

      expect(prisma.codigoVerificacion.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ usedAt: expect.any(Date) }),
        }),
      );
    });

    it('avisa cuando no hay ningún código pendiente', async () => {
      prisma.codigoVerificacion.findFirst.mockResolvedValue(null);

      await expect(
        service.consumir(USUARIO, TipoCodigo.VERIFICACION_EMAIL, '123456'),
      ).rejects.toThrow(/no hay ningún código pendiente/i);
    });
  });
});
