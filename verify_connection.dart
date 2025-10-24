import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('🔍 VERIFICACIÓN DE CONEXIÓN A BASE DE DATOS');
  print('=========================================');

  // 1. Verificar carga de variables de entorno
  try {
    await dotenv.load(fileName: '.env.development');
    print('✅ Variables de entorno cargadas desde .env.development');
  } catch (e) {
    print('⚠️ No se pudo cargar .env.development: $e');
    try {
      await dotenv.load(fileName: '.env.example');
      print('✅ Variables de entorno cargadas desde .env.example');
    } catch (e2) {
      print('⚠️ No se pudo cargar .env.example: $e2');
      print('ℹ️ Usando valores por defecto');
    }
  }

  // 2. Mostrar variables de entorno
  print('\n📋 VARIABLES DE ENTORNO:');
  print('   DB_HOST: ${dotenv.env['DB_HOST'] ?? 'NO DEFINIDO'}');
  print('   DB_PORT: ${dotenv.env['DB_PORT'] ?? 'NO DEFINIDO'}');
  print('   DB_NAME: ${dotenv.env['DB_NAME'] ?? 'NO DEFINIDO'}');
  print('   DB_USER: ${dotenv.env['DB_USER'] ?? 'NO DEFINIDO'}');
  print('   DB_PASSWORD: ${dotenv.env['DB_PASSWORD']?.substring(0, 8) ?? 'NO DEFINIDO'}...');
  print('   DB_SSL_MODE: ${dotenv.env['DB_SSL_MODE'] ?? 'NO DEFINIDO'}');

  // 3. Verificar que las variables críticas estén definidas
  print('\n🔍 VALIDACIÓN:');
  final requiredVars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
  var allValid = true;

  for (final varName in requiredVars) {
    final value = dotenv.env[varName];
    if (value == null || value.isEmpty) {
      print('   ❌ $varName: NO DEFINIDO');
      allValid = false;
    } else {
      print('   ✅ $varName: ${varName == 'DB_PASSWORD' ? '***' : value}');
    }
  }

  // 4. Verificar que el host no sea localhost (debería ser Clever Cloud)
  final host = dotenv.env['DB_HOST'];
  if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
    print('\n⚠️ ADVERTENCIA: Estás usando configuración local');
    print('   Para producción, DB_HOST debería ser tu URL de Clever Cloud');
  } else {
    print('\n✅ Configuración de producción detectada');
    print('   Host: $host');
  }

  // 5. Resumen
  print('\n🎯 RESUMEN:');
  if (allValid && !host!.contains('localhost')) {
    print('   ✅ Configuración lista para producción');
    print('   ✅ Todas las variables requeridas están definidas');
    print('   ✅ Usando credenciales de Clever Cloud');
    print('\n🚀 La aplicación debería conectarse correctamente a tu base de datos');
  } else if (allValid) {
    print('   ✅ Configuración válida para desarrollo');
    print('   ⚠️ Usando configuración local (localhost)');
    print('\n💻 Para desarrollo local está bien, pero para producción usa Clever Cloud');
  } else {
    print('   ❌ Configuración incompleta');
    print('   🔧 Revisa que todas las variables de entorno estén definidas');
  }

  print('\n📱 PRÓXIMOS PASOS:');
  print('   1. Abre la aplicación Flutter');
  print('   2. Toca el icono de red (🌐) en la barra superior');
  print('   3. Verifica que se conecte correctamente a Clever Cloud');
}
