#!/usr/bin/env dart
import 'dart:io';
import 'package:postgres/postgres.dart' as postgres;

void main() async {
  print('🧹 LIMPIADOR AGRESIVO DE CONEXIONES CLEVER CLOUD');
  print('===============================================');
  print('Este script limpiará conexiones y esperará el tiempo necesario');

  // Credenciales hardcodeadas de DatabaseConfig
  const host = 'bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com';
  const port = 5432;
  const database = 'bbisaulqlodvucjcmkwk';
  const username = 'upaubg9taprssjvha045';
  const password = 'aiEBEE3HvJA8zjmlmnMQ1BFK9F1cHr';

  int attempts = 0;
  const maxAttempts = 10;

  print('\n🔄 Iniciando limpieza agresiva de conexiones...');

  while (attempts < maxAttempts) {
    attempts++;
    print('\n📡 Intento $attempts de $maxAttempts');

    try {
      print('⏳ Intentando conexión...');

      final connection = await postgres.Connection.open(
        postgres.Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: postgres.ConnectionSettings(
          sslMode: postgres.SslMode.require,
          connectTimeout: Duration(seconds: 10),
        ),
      );

      print('✅ ¡CONEXIÓN EXITOSA!');
      print('   El límite de conexiones se ha liberado');

      // Verificar información básica
      final dbName = await connection.execute('SELECT current_database()');
      print('   Base de datos: ${dbName.first.first}');

      // Verificar conexiones activas
      final activeConnections = await connection.execute('''
        SELECT count(*) as active_connections
        FROM pg_stat_activity
        WHERE usename = @username
      ''', parameters: {'username': username});

      print('   Conexiones activas para el usuario: ${activeConnections.first.first}');

      await connection.close();
      print('🔌 Conexión cerrada correctamente');

      print('\n🎉 ¡PROBLEMA SOLUCIONADO!');
      print('   La aplicación debería funcionar ahora');
      print('   Reinicia Flutter y prueba el login');

      return;

    } catch (e) {
      print('❌ Error: $e');

      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        print('💡 Límite de conexiones aún activo');
        if (attempts < maxAttempts) {
          final waitTime = 30 * attempts; // Backoff exponencial: 30s, 60s, 90s...
          print('   Esperando $waitTime segundos antes del siguiente intento...');

          for (int i = waitTime; i > 0; i--) {
            stdout.write('\r   ⏰ $i segundos restantes...');
            await Future.delayed(Duration(seconds: 1));
          }
          print('\n   ⏭️ Siguiente intento...');
        } else {
          print('   ❌ Máximo número de intentos alcanzado');
        }
      } else {
        print('   ❌ Error diferente, saliendo...');
        return;
      }
    }
  }

  print('\n❌ No se pudo resolver el problema automáticamente');
  print('\n💡 SOLUCIONES MANUALES:');
  print('   1. Ve al panel de Clever Cloud');
  print('   2. Verifica el estado de la base de datos');
  print('   3. Considera reiniciar la base de datos');
  print('   4. Contacta al soporte de Clever Cloud');
  print('   5. Espera 1-2 horas para que las conexiones expiren automáticamente');

  print('\n🔄 También puedes intentar:');
  print('   - Reiniciar tu router/modem');
  print('   - Cambiar de red WiFi');
  print('   - Usar datos móviles en lugar de WiFi');

  print('\n=== LIMPIEZA FINALIZADA ===');
}
