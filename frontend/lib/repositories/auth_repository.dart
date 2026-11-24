import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;
}

class AuthRepository {
  Future<AuthResult> login({required String email, required String password}) async {
    final data = asMap(
      await ApiClient.instance.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      ),
    );

    return AuthResult(
      token: asString(data['token']),
      user: User.fromJson(asMap(data['user'])),
    );
  }

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );

    return User.fromJson(asMap(data));
  }

  Future<User> me() async {
    final data = await ApiClient.instance.get('/auth/me');
    return User.fromJson(asMap(data));
  }
}
