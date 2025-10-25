#!/usr/bin/env dart
import 'package:anunciacion/src/infrastructure/db/database_config.dart';

void main() async {
  print('🔍 PRUEBA DIRECTA DE AUTENTICACIÓN');
  print('===================================');

  try {
    print('📡 Probando conexión...');
    final dbConfig = DatabaseConfig.instance;
    await dbConfig.resetConnection();

    final connection = await dbConfig.database;

    print('✅ Conexión exitosa!');

    // Probar consulta directa de autenticación
    print('\n🔐 Probando consulta de autenticación directa...');
    final result = await connection.execute(
      'SELECT * FROM usuarios WHERE username = @username AND password = @password AND estado = @estado',
      parameters: {
        'username': 'admin',
        'password': 'admin123',
        'estado': 'activo'
      }
    );

    print('📊 Resultados encontrados: ${result.length}');

    if (result.isNotEmpty) {
      print('✅ Usuario encontrado!');
      print('📋 Datos del usuario:');
      for (int i = 0; i < result.first.length; i++) {
        print('   Columna $i: ${result.first[i]}');
      }
    } else {
      print('❌ Usuario no encontrado');

      // Verificar si la tabla existe
      print('\n🔍 Verificando tabla usuarios...');
      final tables = await connection.execute('''
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'usuarios'
      ''');

      if (tables.isEmpty) {
        print('❌ Tabla "usuarios" no existe');
        print('💡 Necesitas ejecutar el script de creación de base de datos');
      } else {
        print('✅ Tabla "usuarios" existe');

        // Verificar usuarios existentes
        print('\n👥 Usuarios en la base de datos:');
        final users = await connection.execute('SELECT username, estado FROM usuarios');
        if (users.isEmpty) {
          print('   ❌ No hay usuarios en la tabla');
          print('   💡 Ejecuta el script de inserción de datos iniciales');
        } else {
          for (final user in users) {
            print('   - ${user[0]} (${user[1]})');
          }
        }
      }
    }

    await connection.close();
    await dbConfig.close();

  } catch (e) {
    print('\n❌ ERROR: $e');

    if (e.toString().contains('53300')) {
      print('💡 Límite de conexiones alcanzado');
      print('   Ejecuta: dart run emergency_clean.dart');
    } else if (e.toString().contains('42P01')) {
      print('💡 Tabla no existe');
      print('   Ejecuta el script de creación de base de datos');
    }
  }

  print('\n=== PRUEBA COMPLETADA ===');
}
