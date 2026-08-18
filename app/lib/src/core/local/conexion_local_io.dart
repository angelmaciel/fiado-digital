import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abre la base local cifrada (Android y Windows).
///
/// El binario que se empaqueta es el de SQLCipher, elegido en el `pubspec.yaml`
/// con los hooks de `package:sqlite3`.
QueryExecutor abrirBaseLocal({required String claveDeCifrado}) {
  return LazyDatabase(() async {
    final carpeta = await getApplicationSupportDirectory();
    final archivo = File(p.join(carpeta.path, 'fiado_digital.db'));

    return NativeDatabase(
      archivo,
      setup: (db) {
        // `PRAGMA key` tiene que ser lo primero que se ejecuta: antes de eso el
        // archivo no se puede ni leer ni escribir. Las comillas simples se
        // duplican porque el pragma no acepta parametros ligados.
        final clave = claveDeCifrado.replaceAll("'", "''");
        db.execute("PRAGMA key = '$clave';");

        // Si el binario empaquetado no fuera el de SQLCipher, este pragma
        // devuelve vacio. Vale la pena que reviente aca y no que la base quede
        // guardando fiados en texto plano sin que nadie se entere.
        final version = db.select('PRAGMA cipher_version;');
        if (version.isEmpty) {
          throw StateError(
            'El SQLite empaquetado no soporta cifrado. Revisá la sección '
            '`hooks` del pubspec.yaml.',
          );
        }

        // Una clave equivocada no falla al abrir, sino recien al leer. Se fuerza
        // una lectura para que el error aparezca donde se entiende.
        db.execute('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}

bool get hayBaseLocalDisponible => true;
