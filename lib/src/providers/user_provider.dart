import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/entities.dart';
import '../infrastructure/repositories/user_repository_impl.dart';

// Provider para el estado del usuario autenticado
final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(UserRepositoryImpl());
});

// Notifier para manejar el estado del usuario
class UserNotifier extends StateNotifier<User?> {
  final UserRepositoryImpl _userRepository;

  UserNotifier(this._userRepository) : super(null);

  Future<bool> login(String username, String password) async {
    try {
      final user = await _userRepository.authenticate(username, password);
      if (user != null) {
        state = user;
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<bool> authenticate(String username, String password) async {
    return await login(username, password);
  }

  Future<bool> createUser({
    required String name,
    required String username,
    required String password,
    required int roleId,
  }) async {
    try {
      final newUser = User.create(
        name: name,
        username: username,
        plainPassword: password,
        roleId: roleId,
      );

      final savedUser = await _userRepository.save(newUser);
      if (savedUser.id > 0) {
        state = savedUser;
        return true;
      }
      return false;
    } catch (e) {
      print('Error creando usuario: $e');
      return false;
    }
  }

  void logout() {
    state = null;
  }
}
