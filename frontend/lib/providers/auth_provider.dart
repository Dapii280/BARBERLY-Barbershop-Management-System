import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  User? _user;
  bool _initialized = false;
  bool _bootstrapping = false;
  bool _loading = false;
  bool _uploadingPhoto = false;
  String? _error;

  User? get user => _user;
  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get uploadingPhoto => _uploadingPhoto;
  String? get error => _error;

  /// Membaca sesi tersimpan lalu memvalidasi token ke server.
  Future<void> bootstrap() async {
    if (_initialized || _bootstrapping) return;
    _bootstrapping = true;

    await ApiClient.instance.loadToken();
    final cachedUser = await SecureStorage.getUser();
    if (cachedUser != null) {
      _user = User.fromJson(cachedUser);
    }

    if (ApiClient.instance.hasToken) {
      try {
        final freshUser = await _authRepository.me();
        _user = freshUser;
        await SecureStorage.saveUser(freshUser.toJson());
      } on ApiException catch (error) {
        if (error.isUnauthorized) {
          await _clearSession();
        }
      }
    } else {
      _user = null;
    }

    _initialized = true;
    _bootstrapping = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(email: email, password: password);
      _user = result.user;
      ApiClient.instance.setToken(result.token);
      await SecureStorage.saveToken(result.token);
      await SecureStorage.saveUser(result.user.toJson());
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? password,
    String? currentPassword,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _userRepository.updateMe(
        name: name,
        phone: phone,
        password: password,
        currentPassword: currentPassword,
      );
      _user = updated;
      await SecureStorage.saveUser(updated.toJson());
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto(XFile file) async {
    _uploadingPhoto = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _userRepository.uploadPhoto(file);
      _user = updated;
      await SecureStorage.saveUser(updated.toJson());
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _uploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!ApiClient.instance.hasToken) return;

    try {
      final freshUser = await _authRepository.me();
      _user = freshUser;
      await SecureStorage.saveUser(freshUser.toJson());
      notifyListeners();
    } on ApiException catch (_) {
      // Profil lama tetap dipakai bila refresh gagal.
    }
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  /// Dipanggil interceptor saat server membalas 401.
  void forceLogout() {
    _user = null;
    notifyListeners();
    SecureStorage.clear();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    ApiClient.instance.setToken(null);
    await SecureStorage.clear();
    _user = null;
  }
}
