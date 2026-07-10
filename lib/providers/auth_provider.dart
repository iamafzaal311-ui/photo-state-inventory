import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;

  const AuthState({this.currentUser, this.isLoading = false, this.error});

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.role == 'admin';

  AuthState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 300));
    final user = AuthService.login(username, password);
    if (user != null) {
      state = AuthState(currentUser: user);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: 'Invalid username or password');
      return false;
    }
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final allUsersProvider = Provider<List<UserModel>>((ref) {
  ref.watch(authProvider);
  return AuthService.getAllUsers();
});
