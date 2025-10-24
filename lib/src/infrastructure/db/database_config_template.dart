import 'package:postgres/postgres.dart' as postgres;

class DatabaseConfig {
  // TODO: Replace with your actual Clever Cloud PostgreSQL credentials
  // You can find these in your Clever Cloud dashboard
  static const String _host = 'YOUR_CLEVER_CLOUD_HOST';
  static const int _port = 5432;
  static const String _databaseName = 'YOUR_DATABASE_NAME';
  static const String _username = 'YOUR_USERNAME';
  static const String _password = 'YOUR_PASSWORD';
  static const postgres.SslMode _sslMode = postgres.SslMode.require;

  DatabaseConfig._privateConstructor();
  static final DatabaseConfig instance = DatabaseConfig._privateConstructor();

  static postgres.Connection? _connection;

  Future<postgres.Connection> get database async {
    _connection ??= await _initDatabase();
    return _connection!;
  }

  Future<postgres.Connection> _initDatabase() async {
    try {
      print('🔗 Conectando a PostgreSQL...');
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
        settings: postgres.ConnectionSettings(sslMode: _sslMode),
      );

      print('✅ Conexión exitosa!');
      print('   Base de datos lista para usar');

      return connection;
    } catch (e) {
      print('❌ Error de conexión: $e');
      print('   Reemplaza las credenciales con las de tu base de datos');
      rethrow;
    }
  }

  // Simple connection test - only checks if connection can be established
  Future<bool> testConnection() async {
    try {
      // Just try to open connection without executing any SQL
      final connection = await _initDatabase();
      await connection.close();
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }
}
