import { TipoMovimiento } from '@prisma/client';
import { PrismaService } from '../common/prisma/prisma.service';
import { ClientesService } from './clientes.service';

/**
 * HU-06. La definición de mora fue una decisión de diseño discutible —se mide
 * desde el último pago, no desde la última compra— así que conviene que quede
 * fijada por tests y no solo por un comentario.
 */
describe('ClientesService.listarEnMora', () => {
  const DESPENSA = 'despensa-1';

  let prisma: {
    despensa: { findUnique: jest.Mock };
    cliente: { findMany: jest.Mock };
    movimiento: { groupBy: jest.Mock };
  };
  let service: ClientesService;

  const haceDias = (dias: number) =>
    new Date(Date.now() - dias * 24 * 60 * 60 * 1000);

  function armar({
    diasMoraConfig = 30,
    deudores = [] as Array<{
      id: string;
      nombre: string;
      telefono: string | null;
      saldoActual: number;
    }>,
    ultimosPagos = [] as Array<{ clienteId: string; fecha: Date }>,
    primerosMovimientos = [] as Array<{ clienteId: string; fecha: Date }>,
  }) {
    prisma = {
      despensa: { findUnique: jest.fn().mockResolvedValue({ diasMoraConfig }) },
      cliente: { findMany: jest.fn().mockResolvedValue(deudores) },
      movimiento: {
        groupBy: jest
          .fn()
          // La primera llamada trae el último pago; la segunda, el primer
          // movimiento de cada cliente.
          .mockImplementationOnce(() =>
            Promise.resolve(
              ultimosPagos.map((p) => ({
                clienteId: p.clienteId,
                _max: { createdAt: p.fecha },
              })),
            ),
          )
          .mockImplementationOnce(() =>
            Promise.resolve(
              primerosMovimientos.map((p) => ({
                clienteId: p.clienteId,
                _min: { createdAt: p.fecha },
              })),
            ),
          ),
      },
    };

    service = new ClientesService(prisma as unknown as PrismaService);
  }

  it('marca en mora a quien no paga hace más de los días configurados', async () => {
    armar({
      diasMoraConfig: 30,
      deudores: [
        { id: '1', nombre: 'Nimia', telefono: null, saldoActual: 200000 },
      ],
      ultimosPagos: [{ clienteId: '1', fecha: haceDias(70) }],
      primerosMovimientos: [{ clienteId: '1', fecha: haceDias(90) }],
    });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.datos).toHaveLength(1);
    expect(lista.datos[0].diasSinPagar).toBe(70);
    expect(lista.datos[0].nuncaPago).toBe(false);
  });

  it('NO marca en mora a quien pagó hace poco, aunque deba mucho', async () => {
    // La decisión de diseño: la mora la define la plata que entra, no la deuda.
    armar({
      deudores: [
        { id: '1', nombre: 'Aníbal', telefono: null, saldoActual: 900000 },
      ],
      ultimosPagos: [{ clienteId: '1', fecha: haceDias(3) }],
      primerosMovimientos: [{ clienteId: '1', fecha: haceDias(200) }],
    });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.datos).toHaveLength(0);
  });

  it('SÍ marca en mora a quien compró ayer pero no paga hace meses', async () => {
    // El caso inverso, que es el que más se malinterpreta.
    armar({
      deudores: [
        { id: '1', nombre: 'Zulma', telefono: null, saldoActual: 53000 },
      ],
      ultimosPagos: [{ clienteId: '1', fecha: haceDias(42) }],
      primerosMovimientos: [{ clienteId: '1', fecha: haceDias(60) }],
    });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.datos).toHaveLength(1);
    expect(lista.datos[0].diasSinPagar).toBe(42);
  });

  it('cuenta desde el primer movimiento a quien nunca pagó', async () => {
    armar({
      deudores: [
        { id: '1', nombre: 'Eligio', telefono: null, saldoActual: 83000 },
      ],
      ultimosPagos: [],
      primerosMovimientos: [{ clienteId: '1', fecha: haceDias(85) }],
    });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.datos[0].diasSinPagar).toBe(85);
    expect(lista.datos[0].nuncaPago).toBe(true);
    expect(lista.datos[0].ultimoPago).toBeNull();
  });

  it('respeta el umbral configurado en la despensa', async () => {
    const deudores = [
      { id: '1', nombre: 'Mirta', telefono: null, saldoActual: 50000 },
    ];
    const pagos = [{ clienteId: '1', fecha: haceDias(20) }];

    armar({ diasMoraConfig: 30, deudores, ultimosPagos: pagos });
    expect((await service.listarEnMora(DESPENSA)).datos).toHaveLength(0);

    armar({ diasMoraConfig: 15, deudores, ultimosPagos: pagos });
    expect((await service.listarEnMora(DESPENSA)).datos).toHaveLength(1);
  });

  it('ordena por antigüedad y desempata por monto', async () => {
    armar({
      deudores: [
        { id: '1', nombre: 'Chico', telefono: null, saldoActual: 10000 },
        { id: '2', nombre: 'Viejo', telefono: null, saldoActual: 5000 },
        { id: '3', nombre: 'Grande', telefono: null, saldoActual: 90000 },
      ],
      ultimosPagos: [
        { clienteId: '1', fecha: haceDias(40) },
        { clienteId: '2', fecha: haceDias(80) },
        { clienteId: '3', fecha: haceDias(40) },
      ],
    });

    const lista = await service.listarEnMora(DESPENSA);

    // Primero el más atrasado; entre los de 40 días, el que más debe.
    expect(lista.datos.map((c) => c.nombre)).toEqual([
      'Viejo',
      'Grande',
      'Chico',
    ]);
  });

  it('suma cuánto se debe entre todos los atrasados', async () => {
    armar({
      deudores: [
        { id: '1', nombre: 'Uno', telefono: null, saldoActual: 30000 },
        { id: '2', nombre: 'Dos', telefono: null, saldoActual: 70000 },
      ],
      ultimosPagos: [
        { clienteId: '1', fecha: haceDias(40) },
        { clienteId: '2', fecha: haceDias(50) },
      ],
    });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.deudaEnMora).toBe(100000);
  });

  it('no consulta movimientos si nadie debe nada', async () => {
    armar({ deudores: [] });

    const lista = await service.listarEnMora(DESPENSA);

    expect(lista.datos).toHaveLength(0);
    expect(prisma.movimiento.groupBy).not.toHaveBeenCalled();
  });

  it('ignora a un deudor sin ningún movimiento detrás', async () => {
    // No debería existir, pero si existiera no hay desde cuándo contar y no
    // tiene que romper el listado.
    armar({
      deudores: [
        { id: 'huerfano', nombre: 'Raro', telefono: null, saldoActual: 5000 },
      ],
      ultimosPagos: [],
      primerosMovimientos: [],
    });

    await expect(service.listarEnMora(DESPENSA)).resolves.toMatchObject({
      datos: [],
    });
  });

  it('el tipo consultado para el último pago es PAGO', async () => {
    armar({
      deudores: [{ id: '1', nombre: 'Uno', telefono: null, saldoActual: 1000 }],
      ultimosPagos: [],
      primerosMovimientos: [{ clienteId: '1', fecha: haceDias(5) }],
    });

    await service.listarEnMora(DESPENSA);

    expect(prisma.movimiento.groupBy).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        where: expect.objectContaining({ tipo: TipoMovimiento.PAGO }),
      }),
    );
  });
});
