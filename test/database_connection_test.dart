import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart' as postgres;

void main() {
  group('Database Connection Tests', () {
    test('Database connection test - basic connectivity only', () async {
      print('=== PRUEBA DE CONEXIÓN BÁSICA A CLEVER CLOUD ===');
      print('Timestamp: ${DateTime.now()}');

      try {
        // Hardcoded Clever Cloud credentials
        const host = 'bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com';
        const port = 5432;
        const database = 'bbisaulqlodvucjcmkwk';
        const username = 'upaubg9taprssjvha045';
        const password = 'aiEBEE3HvJA8zjmlmnMQ1BFK9F1cHr';

        print('1. Configuración de conexión:');
        print('   Host: $host');
        print('   Port: $port');
        print('   Database: $database');
        print('   Username: $username');
        print('   SSL Mode: require');
        print('   Schema: public (por defecto)');

        // Probar conexión directa (solo conectividad)
        print('2. Probando conectividad básica...');
        final connection = await postgres.Connection.open(
          postgres.Endpoint(
            host: host,
            port: port,
            database: database,
            username: username,
            password: password,
          ),
          settings: postgres.ConnectionSettings(sslMode: postgres.SslMode.require),
        );

        print('✅ CONEXIÓN EXITOSA!');
        print('   - Credenciales válidas');
        print('   - Base de datos accesible');
        print('   - SSL funcionando correctamente');
        print('   - Schema public configurado por defecto');

        // Solo cerrar conexión sin ejecutar más SQL
        print('3. Cerrando conexión...');
        await connection.close();
        print('✅ Conexión cerrada exitosamente');

        print('\n🎉 PRUEBA COMPLETADA - Sin modificaciones a la base de datos');

      } catch (e, stackTrace) {
        print('❌ ERROR DE CONEXIÓN!');
        print('Error: $e');
        print('StackTrace: $stackTrace');

        if (e.toString().contains('Connection refused')) {
          print('💡 Verifica configuración de red');
        } else if (e.toString().contains('authentication failed')) {
          print('💡 Verifica credenciales hardcodeadas');
        } else if (e.toString().contains('does not exist')) {
          print('💡 Verifica nombre de base de datos en schema public');
        } else if (e.toString().contains('SSL')) {
          print('💡 Verifica configuración SSL');
        }

        rethrow;
      }

      print('=== PRUEBA FINALIZADA ===');
    });
  });
}
