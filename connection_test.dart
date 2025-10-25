#!/usr/bin/env dart

import 'package:postgres/postgres.dart' as postgres;

void main() async {
  print('🔍 PRUEBA DIRECTA DE CONEXIÓN A CLEVER CLOUD');
  print('===========================================');

  // Credenciales hardcodeadas de DatabaseConfig
  const host = 'bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com';
  const port = 5432;
  const database = 'bbisaulqlodvucjcmkwk';
  const username = 'upaubg9taprssjvha045';
  const password = 'aiEBEE3HvJA8zjmlmnMQ1BFK9F1cHr';

  print('📡 Configuración de conexión:');
  print('   Host: $host');
  print('   Port: $port');
  print('   Database: $database');
  print('   Username: $username');
  print('   SSL Mode: require');

  try {
    print('⏳ Intentando conectar...');

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

    print('✅ ¡CONEXIÓN EXITOSA!');
    print('   Las credenciales son válidas');
    print('   La base de datos está activa');

    // Verificar información básica
    print('\n📋 Información de la base de datos:');
    final version = await connection.execute('SELECT version()');
    print('   Versión: ${version.first.first.toString().substring(0, 50)}...');

    final dbName = await connection.execute('SELECT current_database()');
    print('   Base de datos: ${dbName.first.first}');

    final user = await connection.execute('SELECT current_user');
    print('   Usuario: ${user.first.first}');

    // Verificar si existe la tabla usuarios
    print('\n🔍 Verificando estructura de la base de datos:');
    final tables = await connection.execute('''
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'usuarios'
    ''');

    if (tables.isEmpty) {
      print('   ❌ Tabla "usuarios" no encontrada');
      print('   💡 Necesitas ejecutar el script de creación de tablas');
    } else {
      print('   ✅ Tabla "usuarios" existe');

      // Verificar si hay datos de usuario
      final userCount =
          await connection.execute('SELECT COUNT(*) FROM usuarios');
      print('   📊 Registros en tabla usuarios: ${userCount.first.first}');
    }

    await connection.close();
    print('\n🔌 Conexión cerrada correctamente');
  } catch (e) {
    print('\n❌ ERROR DE CONEXIÓN:');
    print('   $e');

    if (e.toString().contains('authentication failed')) {
      print('\n💡 PROBLEMA: Credenciales inválidas');
      print('   - La base de datos puede haber sido suspendida');
      print('   - Las credenciales pueden haber expirado');
      print('   - Contacta al soporte de Clever Cloud');
      print('\n🔧 SOLUCIÓN:');
      print('   1. Ve a tu panel de Clever Cloud');
      print('   2. Verifica que la base de datos esté activa');
      print('   3. Regenera las credenciales si es necesario');
      print('   4. Actualiza las credenciales en DatabaseConfig');
    } else if (e.toString().contains('Connection refused') ||
        e.toString().contains('No such host')) {
      print('\n💡 PROBLEMA: Conexión de red');
      print('   - Verifica tu conexión a internet');
      print(
          '   - El servicio de Clever Cloud puede estar temporalmente fuera de línea');
    } else if (e.toString().contains('SSL')) {
      print('\n💡 PROBLEMA: Configuración SSL');
      print('   - Clever Cloud requiere SSL para todas las conexiones');
      print('   - El problema podría ser temporal');
    }
  }

  print('\n=== PRUEBA FINALIZADA ===');
}
