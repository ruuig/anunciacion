#!/usr/bin/env dart
import 'package:anunciacion/src/infrastructure/repositories/user_repository_impl.dart';
import 'package:anunciacion/src/infrastructure/db/database_config.dart';

void main() async {
  print('🔍 VERIFICACIÓN DEL SISTEMA DE LOGIN');
  print('=====================================');

  try {
    print('📡 Probando UserRepositoryImpl...');
    final userRepo = UserRepositoryImpl();

    print('\n🔐 Probando autenticación con credenciales por defecto:');
    print('   Username: admin');
    print('   Password: admin123');

    try {
      // Resetear conexión usando el método público de DatabaseConfig
      print('\n🔄 Reiniciando conexiones...');
      final dbConfig = DatabaseConfig.instance;
      await dbConfig.resetConnection();

      final user = await userRepo.authenticate('admin', 'admin123');

      if (user != null) {
        print('✅ LOGIN EXITOSO!');
        print('   Usuario: ${user.name}');
        print('   Username: ${user.username}');
        print('   Role ID: ${user.roleId}');
        print('   Estado: ${user.status}');

        // Cerrar conexiones después del éxito
        await dbConfig.close();
      } else {
        print('❌ LOGIN FALLIDO: Usuario o contraseña incorrectos');

        // Verificar si el usuario existe
        print('\n🔍 Verificando si el usuario existe...');
        try {
          final existingUser = await userRepo.findByUsername('admin');
          if (existingUser != null) {
            print('   ✅ Usuario "admin" existe en la base de datos');
            print('   📋 Datos del usuario:');
            print('      - ID: ${existingUser.id}');
            print('      - Nombre: ${existingUser.name}');
            print('      - Estado: ${existingUser.status}');
          } else {
            print('   ❌ Usuario "admin" no existe en la base de datos');
            print('   💡 Ejecuta el script de creación de base de datos');
          }
        } catch (e) {
          print('   ❌ Error verificando usuario: $e');
        }

        await dbConfig.close();
      }
    } catch (e) {
      print('❌ ERROR EN EL LOGIN: $e');

      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        print('\n💡 LÍMITE DE CONEXIONES ALCANZADO');
        print('   Soluciones:');
        print('   - Espera unos minutos para que se liberen conexiones');
        print('   - Reinicia completamente la aplicación');
        print('   - Ejecuta: dart run clean_connections.dart');
      } else if (e.toString().contains('42883')) {
        print('\n💡 ERROR 42883: function does not exist');
        print('   - Problema con la consulta SQL');
        print('   - Verifica que las tablas existan');
        print('   - Verifica que los nombres de columna sean correctos');
      }
    }

  } catch (e) {
    print('\n❌ ERROR GENERAL: $e');
    print('   Verifica que DatabaseConfig esté configurado correctamente');
  }

  print('\n=== VERIFICACIÓN COMPLETADA ===');
}
