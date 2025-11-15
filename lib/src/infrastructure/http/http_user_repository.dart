import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/value_objects/value_objects.dart';
import 'http_client.dart';

class HttpUserRepository implements UserRepository {
  final HttpClient _httpClient = HttpClient();

  @override
  Future<User> save(User user) async {
    final data = await _httpClient.post('/users', {
      'name': user.name,
      'username': user.username,
      'password': user.passwordHash.toString(), // Enviar la contraseña
      'roleId': user.roleId,
      'phone': user.phone?.value,
      'avatarUrl': user.avatarUrl,
      'status': user.status.value.toString().split('.').last,
    });

    return _mapToUser(data);
  }

  @override
  Future<User?> findById(int id) async {
    try {
      final data = await _httpClient.get('/users/$id');
      return _mapToUser(data);
    } catch (e) {
      print('Error finding user by id: $e');
      return null;
    }
  }

  @override
  Future<List<User>> findAll() async {
    final data = await _httpClient.getList('/users');
    return data.map((json) => _mapToUser(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<User> update(User user) async {
    final data = await _httpClient.put('/users/${user.id}', {
      'name': user.name,
      'username': user.username,
      'roleId': user.roleId,
      'phone': user.phone?.value,
      'avatarUrl': user.avatarUrl,
      'status': user.status.value.toString().split('.').last,
    });

    return _mapToUser(data);
  }

  @override
  Future<void> delete(int id) async {
    await _httpClient.delete('/users/$id');
  }

  @override
  Future<User?> findByUsername(String username) async {
    try {
      final data = await _httpClient.get('/users/username/$username');
      return _mapToUser(data);
    } catch (e) {
      print('Error finding user by username: $e');
      return null;
    }
  }

  @override
  Future<User?> findByEmail(String email) async {
    try {
      final data = await _httpClient.get('/users/email/$email');
      return _mapToUser(data);
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  @override
  Future<List<User>> findByRole(int roleId) async {
    final data = await _httpClient.getList('/users?roleId=$roleId');
    return data.map((json) => _mapToUser(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<User>> findActiveUsers() async {
    final data = await _httpClient.getList('/users?status=activo');
    return data.map((json) => _mapToUser(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> existsByUsername(String username) async {
    try {
      await _httpClient.get('/users/username/$username');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> authenticate(String username, String password) async {
    try {
      final data = await _httpClient.post('/api/auth/login', {
        'username': username,
        'password': password,
      });

      return _mapToUser(data);
    } catch (e) {
      print('❌ Error authenticating user: $e');
      return null;
    }
  }

  @override
  Future<void> updateLastAccess(int userId) async {
    await _httpClient.put('/users/$userId/last-access', {});
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    await _httpClient.put('/users/$userId/role', {'role': newRole});
  }

  @override
  Future<bool> existsById(int id) async {
    try {
      await _httpClient.get('/users/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  User _mapToUser(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      passwordHash: Password.fromPlainText(''), // No necesitamos la contraseña del backend
      roleId: json['roleId'] ?? 0,
      phone: null, // No necesitamos el teléfono aquí
      status: UserStatus.fromString(json['status'] ?? 'activo'),
      avatarUrl: json['avatarUrl'],
      lastAccess: json['lastAccess'] != null
          ? DateTime.parse(json['lastAccess'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
