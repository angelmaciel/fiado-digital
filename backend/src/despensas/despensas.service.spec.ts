import { TipoMovimiento } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { DespensasService } from './despensas.service';

/**
 * El resumen es lo que le dice al despensero si su negocio va bien o mal. Un
 * error acá no rompe nada visible: simplemente le miente.
 */
describe('DespensasService.resumen', () => {
  const DESPENSA = 'despensa-1';

  let prisma: {
    despensa: { findUnique: jest.Mock };
    cliente: { findMany: jest.Mock; count: jest.Mock };
    movimiento: { findMany: jest.Mock };
  };
  let service: DespensasService;

  /** Una fecha dentro del mes en curso. */
  const esteMes = (dia = 5) => {
    const hoy = new Date();
    return new Date(hoy.getFullYear(), hoy.getMonth(), dia, 10);
  };

  /** Una fecha del mes anterior. */
  const mesPasado = (dia = 15) => {
    const hoy = new Date();
    return new Date(hoy.getFullYear(), hoy.getMonth() - 1, dia, 10);
  };

  function armar({
    clientes = [] as Array<{
      id: string;
      nombre: string;
      saldoActual: number;
      limiteCredito: number | null;
    }>,
    movimientos = [] as Array<{
      tipo: TipoMovimiento;
      monto: number;
      createdAt: Date;
      original?: { tipo: TipoMovimiento } | null;
    }>,
  }) {
    prisma = {
      despensa: { findUnique: jest.fn().mockResolvedValue({ diasMoraConfig: 30 }) },
      cliente: {
        findMany: jest.fn().mockResolvedValue(clientes),
        count: jest.fn().mockResolvedValue(0),
      },
      movimiento: {
        findMany: jest.fn().mockResolvedValue(
          movimientos.map((m) => ({ ...m, original: m.original ?? null })),
        ),
      },
    };

    service = new DespensasService(prisma as unknown as PrismaService);
  }

  describe('deuda', () => {
    it('suma solo los saldos positivos', async () => {
      armar({
        clientes: [
          { id: '1', nombre: 'Ana', saldoActual: 100000, limiteCredito: null },
          { id: '2', nombre: 'Beto', saldoActual: 0, limiteCredito: null },
          // Un cliente con saldo a favor no resta de lo que le deben a la
          // despensa: son cosas distintas.
          { id: '3', nombre: 'Cielo', saldoActual: -20000, limiteCredito: null },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.deuda.total).toBe(100000);
      expect(resumen.clientes.conDeuda).toBe(1);
      expect(resumen.clientes.alDia).toBe(2);
    });

    it('promedia entre los que deben, no entre todos', async () => {
      // Con 3 clientes y uno solo debiendo 90.000, el promedio sobre todos
      // daría 30.000 y escondería el tamaño real de la deuda.
      armar({
        clientes: [
          { id: '1', nombre: 'Ana', saldoActual: 90000, limiteCredito: null },
          { id: '2', nombre: 'Beto', saldoActual: 0, limiteCredito: null },
          { id: '3', nombre: 'Cielo', saldoActual: 0, limiteCredito: null },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.deuda.promedioPorDeudor).toBe(90000);
    });

    it('cuenta los límites excedidos', async () => {
      armar({
        clientes: [
          { id: '1', nombre: 'Ana', saldoActual: 120000, limiteCredito: 100000 },
          { id: '2', nombre: 'Beto', saldoActual: 50000, limiteCredito: 100000 },
          { id: '3', nombre: 'Cielo', saldoActual: 900000, limiteCredito: null },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.limites.excedidos).toBe(1);
      expect(resumen.limites.sinLimite).toBe(1);
    });

    it('no divide por cero cuando no hay deuda', async () => {
      armar({ clientes: [] });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.deuda.promedioPorDeudor).toBe(0);
      expect(resumen.deuda.concentracionTop3).toBe(0);
    });
  });

  describe('flujo del mes', () => {
    it('separa lo fiado de lo cobrado', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 100000, createdAt: esteMes() },
          { tipo: TipoMovimiento.PAGO, monto: 40000, createdAt: esteMes() },
          { tipo: TipoMovimiento.FIADO, monto: 50000, createdAt: mesPasado() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.esteMes.fiado).toBe(100000);
      expect(resumen.flujo.esteMes.cobrado).toBe(40000);
      expect(resumen.flujo.mesPasado.fiado).toBe(50000);
    });

    it('la variación de deuda es fiado menos cobrado', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 100000, createdAt: esteMes() },
          { tipo: TipoMovimiento.PAGO, monto: 30000, createdAt: esteMes() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.esteMes.variacionDeuda).toBe(70000);
    });

    it('un ajuste resta del mismo concepto que corrige', async () => {
      // Un fiado mal cargado y su corrección en el mismo mes se cancelan.
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 150000, createdAt: esteMes() },
          {
            tipo: TipoMovimiento.AJUSTE,
            monto: 150000,
            createdAt: esteMes(),
            original: { tipo: TipoMovimiento.FIADO },
          },
          { tipo: TipoMovimiento.FIADO, monto: 15000, createdAt: esteMes() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.esteMes.fiado).toBe(15000);
    });

    it('un ajuste sobre un pago descuenta de lo cobrado', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.PAGO, monto: 50000, createdAt: esteMes() },
          {
            tipo: TipoMovimiento.AJUSTE,
            monto: 50000,
            createdAt: esteMes(),
            original: { tipo: TipoMovimiento.PAGO },
          },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.esteMes.cobrado).toBe(0);
    });

    it('una corrección tardía descuenta del mes en que se hizo', async () => {
      // El mes pasado ya está cerrado: no se reescribe. El descuento cae en el
      // mes de la corrección, como en contabilidad.
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 80000, createdAt: mesPasado() },
          {
            tipo: TipoMovimiento.AJUSTE,
            monto: 80000,
            createdAt: esteMes(),
            original: { tipo: TipoMovimiento.FIADO },
          },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.mesPasado.fiado).toBe(80000);
      expect(resumen.flujo.esteMes.fiado).toBe(-80000);
    });
  });

  describe('tasa de recuperación', () => {
    it('es cobrado sobre fiado, en porcentaje', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 100000, createdAt: esteMes() },
          { tipo: TipoMovimiento.PAGO, monto: 75000, createdAt: esteMes() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.tasaRecuperacion).toBe(75);
    });

    it('es null si no se fió nada, en vez de dividir por cero', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.PAGO, monto: 50000, createdAt: esteMes() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.tasaRecuperacion).toBeNull();
    });

    it('puede pasar de 100 cuando se cobra más de lo que se fía', async () => {
      armar({
        movimientos: [
          { tipo: TipoMovimiento.FIADO, monto: 50000, createdAt: esteMes() },
          { tipo: TipoMovimiento.PAGO, monto: 90000, createdAt: esteMes() },
        ],
      });

      const resumen = await service.resumen(DESPENSA);

      expect(resumen.flujo.tasaRecuperacion).toBe(180);
      expect(resumen.flujo.esteMes.variacionDeuda).toBeLessThan(0);
    });
  });
});
