// test/core/auth/ghost_auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/auth/auth_state.dart';
import 'package:sundial/core/auth/ghost_auth_repository.dart';

void main() {
  group('GhostAuthRepository', () {
    late GhostAuthRepository repo;

    setUp(() => repo = GhostAuthRepository());

    test('currentState is ghost tier with null userId', () {
      expect(repo.currentState.tier, AuthTier.ghost);
      expect(repo.currentState.userId, isNull);
    });

    test('authStateStream emits ghost state', () async {
      final state = await repo.authStateStream.first;
      expect(state.tier, AuthTier.ghost);
    });

    test('upgradeToToken throws UnimplementedError in Phase 1', () {
      expect(() => repo.upgradeToToken(), throwsUnimplementedError);
    });

    test('upgradeToNamed throws UnimplementedError in Phase 1', () {
      expect(
        () => repo.upgradeToNamed(email: 'test@test.com'),
        throwsUnimplementedError,
      );
    });
  });
}
