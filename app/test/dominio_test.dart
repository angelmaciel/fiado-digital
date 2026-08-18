import 'package:flutter_test/flutter_test.dart';

import 'package:fiado_digital/src/core/local/sincronizacion.dart';
import 'package:fiado_digital/src/core/network/api_exception.dart';
import 'package:fiado_digital/src/features/movimientos/domain/movimiento.dart';
import 'package:fiado_digital/src/features/perfil/domain/resumen_despensa.dart';
import 'package:fiado_digital/src/features/metodos_pago/domain/metodo_pago.dart';

void main() {
  group('Movimiento.efectoSobreSaldo', () {
    Movimiento crear(TipoMovimiento tipo, int monto) => Movimiento(
      id: 'm1',
      tipo: tipo,
      monto: monto,
      createdAt: DateTime(2026, 8, 17),
      registradoPor: 'Angel',
      revertido: false,
    );

    test('un fiado suma al saldo', () {
      expect(crear(TipoMovimiento.fiado, 50000).efectoSobreSaldo, 50000);
    });

    test('un pago resta', () {
      expect(crear(TipoMovimiento.pago, 20000).efectoSobreSaldo, -20000);
    });

    test('un ajuste no se puede calcular solo con sus datos', () {
      // Su efecto depende de qué movimiento revierte, así que se devuelve null
      // en vez de adivinar un signo.
      expect(crear(TipoMovimiento.ajuste, 50000).efectoSobreSaldo, isNull);
    });

    test('un movimiento nace sincronizado salvo que se diga lo contrario', () {
      expect(crear(TipoMovimiento.fiado, 1000).sincronizado, isTrue);
    });
  });

  group('ResumenDespensa.salud', () {
    ResumenDespensa conTasa(int? tasa, {int? tasaAnterior}) => ResumenDespensa(
      totalClientes: 5,
      clientesConDeuda: 3,
      clientesAlDia: 2,
      nuevosEsteMes: 1,
      nuevosMesPasado: 1,
      deudaTotal: 100000,
      promedioPorDeudor: 33333,
      mayoresDeudores: const [],
      concentracionTop3: 100,
      conLimite: 1,
      sinLimite: 4,
      limitesExcedidos: 0,
      esteMes: const FlujoDelPeriodo(
        fiado: 100000,
        cobrado: 50000,
        variacionDeuda: 50000,
      ),
      mesPasado: const FlujoDelPeriodo(
        fiado: 80000,
        cobrado: 40000,
        variacionDeuda: 40000,
      ),
      tasaRecuperacion: tasa,
      tasaRecuperacionMesPasado: tasaAnterior,
    );

    test('cobrar más de lo que se fía es ir bien', () {
      expect(conTasa(120).salud, SaludDelNegocio.bien);
      expect(conTasa(100).salud, SaludDelNegocio.bien);
    });

    test('entre 85 y 99 es ir justo', () {
      // El corte no está en 100 porque las compras de fin de mes se pagan a
      // principios del siguiente: siempre hay un desfasaje normal.
      expect(conTasa(99).salud, SaludDelNegocio.justo);
      expect(conTasa(85).salud, SaludDelNegocio.justo);
    });

    test('por debajo de 85 la deuda crece de verdad', () {
      expect(conTasa(84).salud, SaludDelNegocio.mal);
      expect(conTasa(30).salud, SaludDelNegocio.mal);
    });

    test('sin fiados en el mes no hay veredicto', () {
      expect(conTasa(null).salud, SaludDelNegocio.sinDatos);
    });

    test('compara contra el mes pasado en puntos', () {
      expect(conTasa(56, tasaAnterior: 63).cambioEnRecuperacion, -7);
      expect(conTasa(70, tasaAnterior: 63).cambioEnRecuperacion, 7);
    });

    test('sin mes anterior no hay comparación', () {
      expect(conTasa(56).cambioEnRecuperacion, isNull);
    });
  });

  group('ApiException', () {
    test('un error sin código de estado es una falla de red', () {
      // Es lo que decide si un fiado se encola para reintentar (HU-07).
      const sinRed = ApiException('No hay conexión');
      expect(sinRed.esFallaDeRed, isTrue);

      const rechazado = ApiException('Monto inválido', statusCode: 400);
      expect(rechazado.esFallaDeRed, isFalse);
    });

    test('reconoce el aviso de límite excedido y sus datos', () {
      const e = ApiException(
        'Se pasa',
        statusCode: 409,
        codigo: kCodigoLimiteExcedido,
        datos: {'excesoDe': 22000, 'limiteCredito': 150000},
      );

      expect(e.excedeLimiteDeCredito, isTrue);
      expect(e.excesoDeLimite, 22000);
      expect(e.limiteDelCliente, 150000);
    });

    test('los datos ausentes no explotan', () {
      const e = ApiException('Algo', statusCode: 409);
      expect(e.excesoDeLimite, 0);
      expect(e.excedeLimiteDeCredito, isFalse);
    });
  });

  group('MetodoPago.comoTexto', () {
    test('arma el texto con cada dato en su renglón', () {
      const metodo = MetodoPago(
        id: '1',
        tipo: TipoMetodoPago.transferencia,
        titular: 'Angel Maciel',
        esPrincipal: true,
        banco: 'Ueno Bank',
        numeroCuenta: '620145878',
      );

      final texto = metodo.comoTexto();

      expect(texto, contains('Titular: Angel Maciel'));
      expect(texto, contains('Banco: Ueno Bank'));
      expect(texto, contains('Cuenta: 620145878'));
      // Sin alias cargado, esa línea no debe aparecer vacía.
      expect(texto, isNot(contains('Alias:')));
    });

    test('incluye el nombre de la despensa cuando se lo pasan', () {
      const metodo = MetodoPago(
        id: '1',
        tipo: TipoMetodoPago.alias,
        titular: 'Angel Maciel',
        esPrincipal: false,
        alias: 'angel.maciel',
      );

      expect(
        metodo.comoTexto(nombreDespensa: 'Despensa Maciel'),
        contains('Despensa Maciel'),
      );
    });

    test('el dato principal es con el que realmente se paga', () {
      const conAlias = MetodoPago(
        id: '1',
        tipo: TipoMetodoPago.alias,
        titular: 'Angel',
        esPrincipal: false,
        alias: 'angel.maciel',
        numeroCuenta: '620145878',
      );
      expect(conAlias.datoPrincipal, 'angel.maciel');

      const soloCuenta = MetodoPago(
        id: '2',
        tipo: TipoMetodoPago.transferencia,
        titular: 'Angel',
        esPrincipal: false,
        numeroCuenta: '620145878',
      );
      expect(soloCuenta.datoPrincipal, '620145878');
    });
  });

  group('EstadoOffline.aviso', () {
    EstadoOffline estado({
      bool hayConexion = true,
      int pendientes = 0,
      bool sincronizando = false,
      bool puedeAnotar = true,
    }) => EstadoOffline(
      hayConexion: hayConexion,
      pendientes: pendientes,
      sincronizando: sincronizando,
      puedeAnotar: puedeAnotar,
    );

    // Esta es la que importa: sin red y sin base local, el fiado no se guarda
    // en ninguna parte. Prometer que se puede seguir anotando hace que el
    // despensero le fíe a alguien y pierda el registro.
    test('sin red y sin base local NO promete que se pueda anotar', () {
      final aviso = estado(hayConexion: false, puedeAnotar: false).aviso;

      expect(aviso, isNot(contains('Podés seguir anotando')));
      expect(aviso, contains('Esperá'));
    });

    test('sin red y sin base local es el caso grave', () {
      expect(estado(hayConexion: false, puedeAnotar: false).esGrave, isTrue);
      expect(estado(hayConexion: false).esGrave, isFalse);
      expect(estado(puedeAnotar: false).esGrave, isFalse);
    });

    test('sin red pero con base local sí invita a seguir anotando', () {
      expect(
        estado(hayConexion: false).aviso,
        'Sin internet. Podés seguir anotando igual.',
      );
    });

    test('sin red con cosas encoladas dice cuántas son', () {
      expect(
        estado(hayConexion: false, pendientes: 3).aviso,
        'Sin internet. 3 movimientos se van a subir solos.',
      );
      expect(
        estado(hayConexion: false, pendientes: 1).aviso,
        'Sin internet. 1 movimiento se va a subir solo.',
      );
    });

    test('con red avisa lo que falta subir, y si está subiendo lo dice', () {
      expect(estado(pendientes: 2).aviso, '2 movimientos sin subir');
      expect(estado(pendientes: 2, sincronizando: true).aviso, 'Subiendo 2…');
    });

    test('no molesta cuando no hay nada que decir', () {
      expect(estado().hayAlgoQueAvisar, isFalse);
      expect(estado(pendientes: 1).hayAlgoQueAvisar, isTrue);
      expect(estado(hayConexion: false).hayAlgoQueAvisar, isTrue);
    });
  });
}
