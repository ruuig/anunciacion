// Provider para gestión de estado de usuarios
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../application/use_cases/use_cases.dart';
import '../../infrastructure/repositories/repositories_impl.dart';
import '../../infrastructure/repositories/role_repository_impl.dart';

// Estado del usuario
class UserState {
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const UserState({
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  UserState copyWith({
    User? currentUser,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Provider de estado de usuario
class UserNotifier extends StateNotifier<UserState> {
  final AuthenticateUserUseCase _authenticateUserUseCase;
  final CreateUserUseCase _createUserUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;

  UserNotifier(
    this._authenticateUserUseCase,
    this._createUserUseCase,
    this._getUserProfileUseCase,
  ) : super(const UserState());

  Future<void> authenticate(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authenticateUserUseCase.execute(
      AuthenticateUserInput(username: username, password: password),
    );

    result.fold(
      (user) {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          isAuthenticated: true,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
          isAuthenticated: false,
        );
      },
    );
  }

  Future<void> createUser({
    required String name,
    required String username,
    required String password,
    required int roleId,
    String? phone,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createUserUseCase.execute(
      CreateUserInput(
        name: name,
        username: username,
        password: password,
        roleId: roleId,
        phone: phone != null ? Phone.fromString(phone) : null,
        avatarUrl: avatarUrl,
      ),
    );

    result.fold(
      (user) {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          isAuthenticated: true,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
          isAuthenticated: false,
        );
      },
    );
  }

  Future<void> getUserProfile(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUserProfileUseCase.execute(userId);

    result.fold(
      (user) {
        state = state.copyWith(
          currentUser: user,
          isLoading: false,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
    );
  }

  void logout() {
    state = const UserState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers usando Riverpod
final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  return UserRepositoryImpl();
});

final authenticateUserUseCaseProvider =
    Provider<AuthenticateUserUseCase>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthenticateUserUseCase(userRepo);
});

final createUserUseCaseProvider = Provider<CreateUserUseCase>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final roleRepo = RoleRepositoryImpl(); // TODO: Implementar RoleRepository
  return CreateUserUseCase(userRepo, roleRepo);
});

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return GetUserProfileUseCase(userRepo);
});

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authenticateUseCase = ref.watch(authenticateUserUseCaseProvider);
  final createUserUseCase = ref.watch(createUserUseCaseProvider);
  final getProfileUseCase = ref.watch(getUserProfileUseCaseProvider);

  return UserNotifier(
    authenticateUseCase,
    createUserUseCase,
    getProfileUseCase,
  );
});
