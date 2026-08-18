import 'package:drift/drift.dart';

/// En Web no hay base local.
///
/// Es una decisión de alcance, no un olvido: el modo sin conexión importa en el
/// celular del mostrador, que es donde el despensero pierde señal. La versión
/// Web ya necesita internet para cargarse, y darle almacenamiento cifrado
/// exigiría una segunda librería de cifrado más los workers de WASM.
///
/// La app detecta que no hay base local y trabaja siempre contra la API.
QueryExecutor abrirBaseLocal({required String claveDeCifrado}) {
  throw UnsupportedError('La base local no está disponible en Web');
}

/// Permite a la app preguntar antes de intentar usarla.
bool get hayBaseLocalDisponible => false;
