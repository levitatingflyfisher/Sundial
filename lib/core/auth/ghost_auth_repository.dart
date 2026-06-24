import 'auth_repository.dart';
import 'auth_state.dart';

class GhostAuthRepository implements AuthRepository {
  static const _ghostState = AuthState(tier: AuthTier.ghost);

  @override
  AuthState get currentState => _ghostState;

  @override
  Stream<AuthState> get authStateStream =>
      Stream.value(_ghostState).asBroadcastStream();

  @override
  Future<void> upgradeToToken() => throw UnimplementedError(
    'Token tier not available in Phase 1. Implement with sanctuary_auth in Phase 2.',
  );

  @override
  Future<void> upgradeToNamed({required String email}) => throw UnimplementedError(
    'Named tier not available in Phase 1. Implement with sanctuary_auth in Phase 2.',
  );

  @override
  Future<void> signOut() async {} // no-op in ghost mode
}
