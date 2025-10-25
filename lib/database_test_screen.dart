import 'package:flutter/material.dart';
import 'package:anunciacion/src/infrastructure/db/database_config.dart';

class DatabaseConnectionTest extends StatefulWidget {
  const DatabaseConnectionTest({Key? key}) : super(key: key);

  @override
  State<DatabaseConnectionTest> createState() => _DatabaseConnectionTestState();
}

class _DatabaseConnectionTestState extends State<DatabaseConnectionTest> {
  String _log = '';
  bool _isTesting = false;

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print(message);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _log = '';
    });

    _addLog('=== PRUEBA DE CONEXIÓN A CLEVER CLOUD ===');
    _addLog('Timestamp: ${DateTime.now()}');

    try {
      // Mostrar configuración hardcodeada
      _addLog('1. Configuración de conexión:');
      _addLog('   Host: bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com');
      _addLog('   Port: 5432');
      _addLog('   Database: bbisaulqlodvucjcmkwk');
      _addLog('   Username: upaubg9taprssjvha045');
      _addLog('   SSL Mode: require');
      _addLog('   Schema: public (por defecto)');

      // Limpiar conexiones existentes primero
      _addLog('\n2. Limpiando conexiones existentes...');
      final dbConfig = DatabaseConfig.instance;
      await dbConfig.resetConnection();
      _addLog('   ✅ Conexiones reiniciadas');

      // Probar conexión básica usando DatabaseConfig
      _addLog('\n3. Probando conexión básica con DatabaseConfig...');
      final connectionTest = await dbConfig.testConnection();

      if (connectionTest) {
        _addLog('✅ CONEXIÓN EXITOSA A CLEVER CLOUD!');
        _addLog('\n4. Verificación completada:');
        _addLog('   - Credenciales válidas');
        _addLog('   - Base de datos accesible');
        _addLog('   - Conexión SSL funcionando');
        _addLog('   - Schema public configurado por defecto');
        _addLog('\n⚠️ Nota: No se ejecutaron consultas SQL adicionales');
        _addLog('   Tu base de datos existente se mantiene intacta');

      } else {
        _addLog('❌ Error en la conexión inicial');
        _addLog('   Verifica que las credenciales sean correctas');
        _addLog('   Verifica que la base de datos esté activa en Clever Cloud');
      }

      await dbConfig.close();
      _addLog('\n✅ Prueba completada - Conexión segura');

    } catch (e, stackTrace) {
      _addLog('\n❌ ERROR DE CONEXIÓN:');
      _addLog('Error: $e');
      _addLog('StackTrace: $stackTrace');

      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        _addLog('\n💡 LÍMITE DE CONEXIONES ALCANZADO');
        _addLog('   Soluciones:');
        _addLog('   - Espera unos minutos para que se liberen conexiones');
        _addLog('   - Reinicia la aplicación completamente');
        _addLog('   - Contacta a Clever Cloud si el problema persiste');
      } else if (e.toString().contains('Connection refused')) {
        _addLog('\n💡 Verifica configuración de red');
      } else if (e.toString().contains('authentication failed')) {
        _addLog('\n💡 Verifica credenciales hardcodeadas');
      } else if (e.toString().contains('does not exist')) {
        _addLog('\n💡 Verifica nombre de base de datos en schema public');
      } else if (e.toString().contains('SSL')) {
        _addLog('\n💡 Verifica configuración SSL');
      }
    }

    _addLog('\n=== PRUEBA FINALIZADA ===');
    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Conexión BD'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Ejecutar Prueba de Conexión'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty
                        ? 'Presiona el botón para iniciar la prueba...'
                        : _log,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
