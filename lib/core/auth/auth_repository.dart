import 'auth_state.dart';

abstract interface class AuthRepository {
  Stream<AuthState> get authStateStream;
  AuthState get currentState;
  Future<void> upgradeToToken();
  Future<void> upgradeToNamed({required String email});
  Future<void> signOut();
}
