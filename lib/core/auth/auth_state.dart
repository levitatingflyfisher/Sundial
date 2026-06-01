enum AuthTier { ghost, token, named }

class AuthState {
  const AuthState({required this.tier, this.userId});
  final AuthTier tier;
  final String? userId;
}
