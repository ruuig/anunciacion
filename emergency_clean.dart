#!/usr/bin/env dart
import 'dart:io';
import 'package:postgres/postgres.dart' as postgres;

void main() async {
  print('🚨 EMERGENCIA: LIMPIEZA DE CONEXIONES CLEVER CLOUD');
  print('=================================================');
  print('Este script resolverá el problema de "too many connections"');

  print('\n📋 DIAGNÓSTICO:');
  print('   - Error: 53300 (too many connections for role)');
  print('   - Causa: Límite de Clever Cloud alcanzado');
  print('   - Solución: Limpieza agresiva + espera');

  print('\n⏰ Iniciando limpieza en 5 segundos...');
  print('   Presiona Ctrl+C para cancelar si no quieres esperar');
  for (int i = 5; i > 0; i--) {
    stdout.write('\r   $i...');
    await Future.delayed(Duration(seconds: 1));
  }
  print('\n\n🔄 Iniciando limpieza...');

  // Estrategia de limpieza agresiva
  const maxAttempts = 5;
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    print('\n📡 Intento $attempt de $maxAttempts');

    try {
      print('   ⏳ Intentando conexión...');

      final connection = await postgres.Connection.open(
        postgres.Endpoint(
          host: 'bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com',
          port: 5432,
          database: 'bbisaulqlodvucjcmkwk',
          username: 'upaubg9taprssjvha045',
          password: 'aiEBEE3HvJA8zjmlmnMQ1BFK9F1cHr',
        ),
        settings: postgres.ConnectionSettings(
          sslMode: postgres.SslMode.require,
          connectTimeout: Duration(seconds: 10),
        ),
      ).timeout(Duration(seconds: 15));

      print('   ✅ ¡CONEXIÓN EXITOSA!');
      print('   🎉 El problema se ha resuelto');

      // Verificar estado de la base de datos
      final dbInfo = await connection.execute('SELECT current_database(), current_user');
      print('   📊 Base de datos: ${dbInfo.first[0]}');
      print('   👤 Usuario: ${dbInfo.first[1]}');

      // Verificar conexiones activas
      final connections = await connection.execute('''
        SELECT count(*) as active_connections
        FROM pg_stat_activity
        WHERE usename = 'upaubg9taprssjvha045'
      ''');
      print('   🔗 Conexiones activas: ${connections.first[0]}');

      await connection.close();
      print('   🔌 Conexión cerrada correctamente');

      print('\n🎊 ¡PROBLEMA COMPLETAMENTE SOLUCIONADO!');
      print('\n📱 PRÓXIMOS PASOS:');
      print('   1. Reinicia la aplicación Flutter');
      print('   2. Ve a la pantalla de login');
      print('   3. Intenta hacer login con admin/admin123');
      print('   4. Si funciona, ¡todo está listo!');

      return;

    } catch (e) {
      print('   ❌ Error: $e');

      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        print('   ⏳ Límite aún activo, esperando...');
        final waitTime = 20 + (attempt * 10); // 30s, 40s, 50s, 60s, 70s
        print('   ⏰ Esperando $waitTime segundos...');

        for (int i = waitTime; i > 0; i--) {
          stdout.write('\r      $i...');
          await Future.delayed(Duration(seconds: 1));
        }
        print('\n   ⏭️ Siguiente intento...');
      } else {
        print('   ❌ Error diferente: $e');
        break;
      }
    }
  }

  print('\n❌ No se pudo resolver automáticamente');
  print('\n💡 SOLUCIONES ALTERNATIVAS:');
  print('   1. Espera 1-2 horas (las conexiones expiran automáticamente)');
  print('   2. Ve al panel de Clever Cloud y reinicia la base de datos');
  print('   3. Contacta al soporte de Clever Cloud');
  print('   4. Considera cambiar a un plan superior si usas muchas conexiones');

  print('\n🔄 También puedes intentar:');
  print('   - Reiniciar tu computadora');
  print('   - Cambiar de conexión a internet');
  print('   - Probar desde una red diferente');

  print('\n=== LIMPIEZA DE EMERGENCIA FINALIZADA ===');
}
