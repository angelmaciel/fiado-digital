import { ConflictException, NotFoundException } from '@nestjs/common';
import { TipoMovimiento } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { TipoMovimientoCreable } from './dto/crear-movimiento.dto';
import { MovimientosService } from './movimientos.service';

/**
 * El núcleo del sistema: acá se decide cuánta plata debe cada cliente. Un error
 * en estas reglas no rompe una pantalla, hace desaparecer o inventar dinero.
 */
describe('MovimientosService', () => {
  const DESPENSA = 'despensa-1';
  const CLIENTE = 'cliente-1';
  const USUARIO = 'usuario-1';

  let prisma: {
    cliente: { findFirst: jest.Mock; update: jest.Mock; findUniqueOrThrow: jest.Mock };
    movimiento: { create: jest.Mock; findUnique: jest.Mock; findFirst: jest.Mock };
    $transaction: jest.Mock;
  };
  let service: MovimientosService;

  const clienteBase = {
    id: CLIENTE,
    despensaId: DESPENSA,
    nombre: 'Ramona Benítez',
    saldoActual: 50000,
    limiteCredito: null as number | null,
  };

  beforeEach(() => {
    prisma = {
      cliente: {
        findFirst: jest.fn().mockResolvedValue({ ...clienteBase }),
        update: jest.fn(),
        findUniqueOrThrow: jest.fn(),
      },
      movimiento: {
        create: jest.fn(),
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn(),
      },
      // La forma de array de $transaction devuelve los resultados de cada
      // sentencia; acá se resuelven las promesas que le pasan.
      $transaction: jest.fn((operaciones: unknown[]) => Promise.all(operaciones)),
    };

    service = new MovimientosService(prisma as unknown as PrismaService);
  });

  /** Captura el `increment` con el que se actualizó el saldo. */
  function saldoMovidoEn(): number {
    const llamada = prisma.cliente.update.mock.calls.at(-1)?.[0];
    return llamada?.data?.saldoActual?.increment;
  }

  describe('el signo del saldo lo determina el tipo', () => {
    it('un fiado suma', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase, saldoActual: 80000 });

      await service.registrar(DESPENSA, CLIENTE, USUARIO, {
        tipo: TipoMovimientoCreable.FIADO,
        monto: 30000,
      });

      expect(saldoMovidoEn()).toBe(30000);
    });

    it('un pago resta', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase, saldoActual: 30000 });

      await service.registrar(DESPENSA, CLIENTE, USUARIO, {
        tipo: TipoMovimientoCreable.PAGO,
        monto: 20000,
      });

      expect(saldoMovidoEn()).toBe(-20000);
    });

    it('el saldo se mueve con increment, no leyendo y escribiendo', async () => {
      // Es lo que impide que dos cobros simultáneos se pisen. Si alguien lo
      // cambiara por `saldoActual: valorCalculado`, este test lo detecta.
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await service.registrar(DESPENSA, CLIENTE, USUARIO, {
        tipo: TipoMovimientoCreable.FIADO,
        monto: 1000,
      });

      const datos = prisma.cliente.update.mock.calls.at(-1)?.[0]?.data;
      expect(datos.saldoActual).toHaveProperty('increment');
    });
  });

  describe('aislamiento por despensa', () => {
    it('no deja registrar sobre un cliente de otra despensa', async () => {
      prisma.cliente.findFirst.mockResolvedValue(null);

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.FIADO,
          monto: 1000,
        }),
      ).rejects.toBeInstanceOf(NotFoundException);

      expect(prisma.movimiento.create).not.toHaveBeenCalled();
    });
  });

  describe('idempotencia (HU-07)', () => {
    it('no vuelve a aplicar un movimiento que ya existe', async () => {
      const yaRegistrado = { id: 'mov-1', clienteId: CLIENTE, monto: 30000 };
      prisma.movimiento.findUnique.mockResolvedValue(yaRegistrado);

      const resultado = await service.registrar(DESPENSA, CLIENTE, USUARIO, {
        id: 'mov-1',
        tipo: TipoMovimientoCreable.FIADO,
        monto: 30000,
      });

      // Lo importante: devuelve el que ya estaba y NO toca el saldo.
      expect(resultado.movimiento).toBe(yaRegistrado);
      expect(prisma.movimiento.create).not.toHaveBeenCalled();
      expect(prisma.cliente.update).not.toHaveBeenCalled();
    });

    it('rechaza reusar un id en otro cliente', async () => {
      prisma.movimiento.findUnique.mockResolvedValue({
        id: 'mov-1',
        clienteId: 'otro-cliente',
      });

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          id: 'mov-1',
          tipo: TipoMovimientoCreable.FIADO,
          monto: 1000,
        }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('respeta la fecha real de un movimiento anotado sin conexión', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await service.registrar(DESPENSA, CLIENTE, USUARIO, {
        tipo: TipoMovimientoCreable.FIADO,
        monto: 1000,
        registradoEn: '2026-08-10T14:30:00.000Z',
      });

      const datos = prisma.movimiento.create.mock.calls.at(-1)?.[0]?.data;
      expect(datos.createdAt).toEqual(new Date('2026-08-10T14:30:00.000Z'));
    });
  });

  describe('límite de crédito (HU-08)', () => {
    beforeEach(() => {
      prisma.cliente.findFirst.mockResolvedValue({
        ...clienteBase,
        saldoActual: 90000,
        limiteCredito: 100000,
      });
    });

    it('deja fiar mientras no se pase', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.FIADO,
          monto: 10000,
        }),
      ).resolves.toBeDefined();
    });

    it('bloquea el fiado que pasa el límite', async () => {
      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.FIADO,
          monto: 20000,
        }),
      ).rejects.toBeInstanceOf(ConflictException);

      expect(prisma.movimiento.create).not.toHaveBeenCalled();
    });

    it('deja pasar si el dueño lo fuerza', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.FIADO,
          monto: 20000,
          forzarLimite: true,
        }),
      ).resolves.toBeDefined();
    });

    it('nunca bloquea un pago', async () => {
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.PAGO,
          monto: 500000,
        }),
      ).resolves.toBeDefined();
    });

    it('no bloquea lo que llega desde el modo sin conexión', async () => {
      // Esa venta ya ocurrió en el mostrador: rechazarla al sincronizar
      // dejaría el saldo del dispositivo distinto del servidor.
      prisma.movimiento.create.mockResolvedValue({ id: 'm1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await expect(
        service.registrar(DESPENSA, CLIENTE, USUARIO, {
          tipo: TipoMovimientoCreable.FIADO,
          monto: 500000,
          registradoEn: '2026-08-10T14:30:00.000Z',
        }),
      ).resolves.toBeDefined();
    });
  });

  describe('corrección de movimientos (HU-10)', () => {
    const fiadoOriginal = {
      id: 'mov-1',
      clienteId: CLIENTE,
      tipo: TipoMovimiento.FIADO,
      monto: 50000,
      reversa: null,
    };

    it('el ajuste aplica el efecto inverso exacto', async () => {
      prisma.movimiento.findFirst.mockResolvedValue(fiadoOriginal);
      prisma.movimiento.create.mockResolvedValue({ id: 'ajuste-1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await service.revertir(DESPENSA, 'mov-1', USUARIO);

      // Revertir un fiado de 50.000 tiene que restar 50.000.
      expect(saldoMovidoEn()).toBe(-50000);
    });

    it('revertir un pago devuelve la deuda', async () => {
      prisma.movimiento.findFirst.mockResolvedValue({
        ...fiadoOriginal,
        tipo: TipoMovimiento.PAGO,
        monto: 20000,
      });
      prisma.movimiento.create.mockResolvedValue({ id: 'ajuste-1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await service.revertir(DESPENSA, 'mov-1', USUARIO);

      expect(saldoMovidoEn()).toBe(20000);
    });

    it('el ajuste referencia al movimiento que corrige', async () => {
      prisma.movimiento.findFirst.mockResolvedValue(fiadoOriginal);
      prisma.movimiento.create.mockResolvedValue({ id: 'ajuste-1' });
      prisma.cliente.update.mockResolvedValue({ ...clienteBase });

      await service.revertir(DESPENSA, 'mov-1', USUARIO);

      const datos = prisma.movimiento.create.mock.calls.at(-1)?.[0]?.data;
      expect(datos.tipo).toBe(TipoMovimiento.AJUSTE);
      expect(datos.movimientoReversaDe).toBe('mov-1');
      expect(datos.monto).toBe(50000);
    });

    it('no deja corregir dos veces el mismo movimiento', async () => {
      prisma.movimiento.findFirst.mockResolvedValue({
        ...fiadoOriginal,
        reversa: { id: 'ajuste-previo' },
      });

      await expect(
        service.revertir(DESPENSA, 'mov-1', USUARIO),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('no deja corregir un ajuste', async () => {
      prisma.movimiento.findFirst.mockResolvedValue({
        ...fiadoOriginal,
        tipo: TipoMovimiento.AJUSTE,
      });

      await expect(
        service.revertir(DESPENSA, 'mov-1', USUARIO),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('no encuentra movimientos de otra despensa', async () => {
      prisma.movimiento.findFirst.mockResolvedValue(null);

      await expect(
        service.revertir(DESPENSA, 'mov-1', USUARIO),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
