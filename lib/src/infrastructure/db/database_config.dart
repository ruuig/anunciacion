import 'package:postgres/postgres.dart' as postgres;

class DatabaseConfig {
  // Hardcoded Clever Cloud PostgreSQL credentials
  static const String _host = 'bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com';
  static const int _port = 5432;
  static const String _databaseName = 'bbisaulqlodvucjcmkwk';
  static const String _username = 'upaubg9taprssjvha045';
  static const String _password = 'aiEBEE3HvJA8zjmlmnMQ1BFK9F1cHr';
  static const postgres.SslMode _sslMode = postgres.SslMode.require;

  DatabaseConfig._privateConstructor();
  static final DatabaseConfig instance = DatabaseConfig._privateConstructor();

  static postgres.Connection? _connection;

  Future<postgres.Connection> get database async {
    // Si ya hay una conexión, verificar si sigue activa con más frecuencia
    if (_connection != null) {
      try {
        // Verificar si la conexión sigue activa con un timeout corto
        await _connection!.execute('SELECT 1').timeout(Duration(seconds: 5));
        return _connection!;
      } catch (e) {
        print('Conexión anterior no válida (${e.toString().substring(0, 50)}...), creando nueva...');
        await _closeConnection();
      }
    }

    _connection = await _initDatabase();
    return _connection!;
  }

  Future<postgres.Connection> _initDatabase() async {
    try {
      print('🔗 Conectando a Clever Cloud PostgreSQL...');
      print('   Host: $_host:$_port');
      print('   Database: $_databaseName');
      print('   SSL: $_sslMode');

      final connection = await postgres.Connection.open(
        postgres.Endpoint(
          host: _host,
          port: _port,
          database: _databaseName,
          username: _username,
          password: _password,
        ),
        settings: postgres.ConnectionSettings(
          sslMode: _sslMode,
          connectTimeout: const Duration(seconds: 30),
          queryTimeout: const Duration(seconds: 30),
        ),
      );

      print('✅ Conexión exitosa a Clever Cloud!');
      print('   Base de datos existente lista para usar');

      return connection;
    } catch (e) {
      print('❌ Error de conexión: $e');
      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        print('💡 LÍMITE DE CONEXIONES ALCANZADO EN CLEVER CLOUD');
        print('   🔄 Intentando reconectar en 10 segundos...');
        await Future.delayed(Duration(seconds: 10));
        return await _initDatabase(); // Retry automático
      } else {
        print('   Verifica que las credenciales sean correctas');
      }
      rethrow;
    }
  }

  // Simple connection test - only checks if connection can be established
  Future<bool> testConnection() async {
    try {
      // Forzar cierre de cualquier conexión existente
      await _closeConnection();

      // Esperar un poco para que se libere la conexión
      await Future.delayed(Duration(seconds: 2));

      // Intentar nueva conexión
      final connection = await _initDatabase();

      // Verificar que funciona con una consulta simple
      await connection.execute('SELECT 1');

      await connection.close();
      // Reset connection para evitar reutilizar
      _connection = null;
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      if (e.toString().contains('53300') || e.toString().contains('too many connections')) {
        print('   💡 Ejecuta: dart run force_clean_connections.dart');
      }
      return false;
    }
  }

  Future<void> _closeConnection() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        print('🔌 Conexión cerrada correctamente');
      } catch (e) {
        print('Error cerrando conexión: $e');
      } finally {
        _connection = null;
      }
    }
  }

  Future<void> close() async {
    await _closeConnection();
  }

  // Método para forzar limpieza de conexiones
  Future<void> resetConnection() async {
    print('🔄 Reiniciando conexión...');
    await _closeConnection();
  }
}
