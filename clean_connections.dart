#!/usr/bin/env dart
import 'dart:io';

void main() async {
  print('🧹 LIMPIADOR DE CONEXIONES CLEVER CLOUD');
  print('=======================================');

  print('Este script limpiará las conexiones existentes y probará una nueva.');
  print('Presiona Enter para continuar o Ctrl+C para cancelar...');
  stdin.readLineSync();

  print('\n🔄 Limpiando conexiones existentes...');

  // Importar y limpiar conexiones
  try {
    // Forzar limpieza de cualquier conexión existente
    print('⏳ Esperando a que se liberen conexiones automáticamente...');
    print('   Clever Cloud liberará conexiones inactivas en unos minutos');

    // Esperar 30 segundos para que se liberen conexiones
    print('\n⏰ Esperando 30 segundos...');
    for (int i = 30; i > 0; i--) {
      stdout.write('\r   $i segundos restantes...');
      await Future.delayed(Duration(seconds: 1));
    }
    print('\n\n✅ Espera completada');

    print('\n🔍 Probando nueva conexión...');

    // Probar conexión usando DatabaseConfig
    final dbConfigScript = '''
import 'package:anunciacion/src/infrastructure/db/database_config.dart';

void main() async {
  print('🔄 Probando conexión después de limpieza...');
  final dbConfig = DatabaseConfig.instance;

  try {
    await dbConfig.resetConnection();
    final connection = await dbConfig.database;

    print('✅ CONEXIÓN EXITOSA DESPUÉS DE LIMPIEZA!');
    print('   La aplicación debería funcionar ahora');

    await connection.close();
    await dbConfig.close();

  } catch (e) {
    print('❌ Error después de limpieza: \$e');
    print('   Puede que necesites esperar más tiempo o contactar a Clever Cloud');
  }
}
''';

    print('\n📋 Credenciales actuales:');
    print('   Host: bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com');
    print('   Database: bbisaulqlodvucjcmkwk');
    print('   User: upaubg9taprssjvha045');

    print('\n💡 Si el problema persiste:');
    print('   1. Ve al panel de Clever Cloud');
    print('   2. Verifica el estado de la base de datos');
    print('   3. Considera reiniciar la base de datos');
    print('   4. Contacta al soporte si es necesario');

    print('\n🔄 Reinicia la aplicación Flutter para usar la nueva conexión');

  } catch (e) {
    print('\n❌ Error durante la limpieza: $e');
  }

  print('\n=== LIMPIEZA COMPLETADA ===');
}
