import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<String?> getToken() => _storage.getToken();

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await _api.login(username, password);
      await _storage.saveToken(response['token']);
      _user = User.fromJson(response['user']);
      await _storage.saveUser(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.register(data);
      await _storage.saveToken(response['token']);
      _user = User.fromJson(response['user']);
      await _storage.saveUser(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user == null) throw Exception('User not logged in');
      if (_user!.email == null || _user!.email!.isEmpty) throw Exception('No email associated with account');
      
      await _api.verifyEmail(_user!.email!, code);
      
      // Refresh user profile to get updated status
      final response = await _api.getMe();
      _user = User.fromJson(response);
      await _storage.saveUser(_user!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_user == null) throw Exception('User not logged in');
      if (_user!.email == null || _user!.email!.isEmpty) throw Exception('No email associated with account');

      await _api.resendVerification(_user!.email!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _api.forgotPassword(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _api.resetPassword(token, newPassword);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUser() async {
    try {
      if (await _storage.hasToken()) {
        try {
          final response = await _api.getMe();
          _user = User.fromJson(response);
          await _storage.saveUser(_user!);
        } catch (e) {
          // Token invalid, clear and require login
          await _storage.clearAll();
          _user = null;
        }
      } else {
        _user = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load user error: $e');
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> ensureAuthenticated() async {
    if (isAuthenticated) {
      // Validate token
      if (await _storage.hasToken()) return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? schoolName,
    String? country,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (schoolName != null) data['school_name'] = schoolName;
      if (country != null) data['country'] = country;

      final response = await _api.updateProfile(data);
      _user = User.fromJson(response);
      await _storage.saveUser(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Wrong username or password.';
      }
      return 'Network error. Please check your connection.';
    }
    if (error.toString().contains('DioException')) {
      if (error.toString().contains('401')) {
        return 'Wrong username or password.';
      }
      return 'Network error. Please check your connection.';
    }
    return error.toString();
  }
}
