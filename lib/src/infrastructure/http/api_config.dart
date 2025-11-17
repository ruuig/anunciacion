/// Configuración de la API del backend
class ApiConfig {
  // URL base del backend en producción (Render)
  static const String baseUrl = 'https://anunciacion-backend.onrender.com';

  // URL local para desarrollo (comentada)
  // static const String baseUrl = 'http://192.168.1.74:3000';

  // Endpoints
  static const String estudiantes = '/api/estudiantes';
  static const String padres = '/api/padres';
  static const String grados = '/api/catalogos/grados';
  static const String secciones = '/api/catalogos/secciones';
  static const String materias = '/api/materias';
  static const String auth = '/api/auth';
  static const String users = '/users';
  static const String attendance = '/api/attendance';

  // Headers comunes
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Construir URL completa
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
