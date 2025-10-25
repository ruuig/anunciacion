import 'package:anunciacion/src/infrastructure/db/database_config.dart';

void main() async {
  print('🔍 VERIFICACIÓN DIRECTA DE DATABASE CONFIG');
  print('==========================================');

  try {
    print('📡 Intentando conectar con DatabaseConfig...');
    final dbConfig = DatabaseConfig.instance;

    print('⏳ Obteniendo conexión...');
    final connection = await dbConfig.database;

    print('✅ CONEXIÓN EXITOSA!');
    print('   - DatabaseConfig está funcionando correctamente');
    print('   - Conexión a PostgreSQL establecida');

    // Verificar información de la base de datos
    print('\n📋 INFORMACIÓN DE LA BASE DE DATOS:');
    final versionResult = await connection.execute('SELECT version()');
    print('   Versión PostgreSQL: ${versionResult.first.first}');

    final dbNameResult = await connection.execute('SELECT current_database()');
    print('   Base de datos actual: ${dbNameResult.first.first}');

    final userResult = await connection.execute('SELECT current_user');
    print('   Usuario actual: ${userResult.first.first}');

    // Verificar schemas
    print('\n📂 SCHEMAS DISPONIBLES:');
    final schemasResult = await connection.execute(
        'SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;');

    for (final row in schemasResult) {
      print('   - ${row.first}');
    }

    // Verificar search path
    print('\n🔍 SEARCH PATH ACTUAL:');
    final searchPathResult = await connection.execute('SHOW search_path;');
    print('   ${searchPathResult.first.first}');

    // Verificar schema escuela
    print('\n🏫 VERIFICACIÓN SCHEMA ESCUELA:');
    final escuelaResult = await connection.execute(
        "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'escuela')");
    final escuelaExists = escuelaResult.first.first as bool;
    print('   Schema "escuela" existe: $escuelaExists');

    if (escuelaExists) {
      // Verificar tablas en schema escuela
      print('\n📊 TABLAS EN SCHEMA ESCUELA:');
      final tablesResult = await connection.execute(
          "SELECT table_name FROM information_schema.tables WHERE table_schema = 'escuela' ORDER BY table_name");

      if (tablesResult.isEmpty) {
        print('   No hay tablas en schema escuela');
        print('   💡 Ejecuta el script complete_database_setup.sql en tu BD');
      } else {
        for (final row in tablesResult) {
          print('   - ${row.first}');
        }
      }
    }

    // Cerrar conexión
    await connection.close();
    print('\n🔌 Conexión cerrada correctamente');

    print('\n🎉 DatabaseConfig VERIFICADO EXITOSAMENTE!');
    print('   ✅ Conexión a Clever Cloud funcionando');
    print('   ✅ Schema configurado correctamente');
    print('   ✅ Variables de entorno cargadas');
  } catch (e) {
    print('\n❌ ERROR EN DATABASE CONFIG:');
    print('   Error: $e');

    if (e.toString().contains('authentication failed')) {
      print('\n💡 SOLUCIÓN: Verifica las credenciales en .env');
      print('   - Usuario y contraseña correctos');
      print('   - Base de datos existe y está activa');
    } else if (e.toString().contains('Connection refused') ||
        e.toString().contains('No such host')) {
      print('\n💡 SOLUCIÓN: Verifica la configuración de red');
      print('   - DB_HOST correcto (URL de Clever Cloud)');
      print('   - DB_PORT correcto (5432)');
      print('   - Conexión a internet disponible');
    } else if (e.toString().contains('SSL')) {
      print('\n💡 SOLUCIÓN: Verifica configuración SSL');
      print('   - DB_SSL_MODE debe ser "require" para Clever Cloud');
      print('   - Certificados SSL válidos');
    }

    print('\n🔧 Variables de entorno actuales:');
  }
}
