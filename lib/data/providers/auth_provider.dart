import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'locale_provider.dart';
import '../../presentation/widgets/country_customization.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  LocaleProvider? _localeProvider;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Inject the [LocaleProvider] so auth events auto-switch the app locale.
  /// Call this once from a ProxyProvider or directly after construction.
  void attachLocaleProvider(LocaleProvider lp) => _localeProvider = lp;

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
      _syncLocale();
      
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
      _syncLocale();
      
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

  /// Pure cache-first auth — like WhatsApp.
  /// If token + cached user exist locally → authenticate instantly, zero network.
  /// Only makes a network call on the very first boot after login (no cache yet).
  /// Background refresh is intentionally removed: it was causing silent session
  /// wipes when the server returned 401 after a redeploy (JWT secret change).
  Future<void> loadUser() async {
    try {
      final hasToken = await _storage.hasToken();
      debugPrint('[AUTH] hasToken=$hasToken');
      if (!hasToken) {
        _user = null;
        notifyListeners();
        return;
      }

      // ── Fast path: cached user found (works fully offline) ──────────────
      final cachedUser = await _storage.getUser();
      debugPrint('[AUTH] cachedUser=${cachedUser?.username}');
      if (cachedUser != null) {
        _user = cachedUser;
        _syncLocale();
        notifyListeners();
        return;
      }

      // ── Slow path: no cached user, must go online ───────────────────────
      debugPrint('[AUTH] No cached user, trying network...');
      try {
        final response = await _api.getMe();
        _user = User.fromJson(response);
        await _storage.saveUser(_user!);
        _syncLocale();
        debugPrint('[AUTH] User fetched and cached: ${_user?.username}');
      } on DioException catch (e) {
        debugPrint('[AUTH] DioException status=${e.response?.statusCode}');
        if (_is401(e)) {
          await _storage.clearAll();
          _user = null;
        }
      } catch (e) {
        debugPrint('[AUTH] Unknown error: $e');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AUTH] Outer catch: $e');
      _user = null;
      notifyListeners();
    }
  }

  bool _is401(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return error.toString().contains('401');
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

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _api.changePassword(currentPassword, newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _is401(e)
          ? 'Current password is incorrect.'
          : _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? schoolName,
    String? country,
    String? languagePreference,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (schoolName != null) data['school_name'] = schoolName;
      if (country != null) {
        data['country'] = country;
        // Derive language from country when no explicit override provided
        data['language_preference'] =
            languagePreference ?? CountryCustomization.getLanguageCode(country);
      } else if (languagePreference != null) {
        data['language_preference'] = languagePreference;
      }

      final response = await _api.updateProfile(data);
      _user = User.fromJson(response);
      await _storage.saveUser(_user!);
      _syncLocale();

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

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Sync the [LocaleProvider] to the user's stored language_preference.
  void _syncLocale() {
    final lp = _localeProvider;
    final langPref = _user?.languagePreference;
    if (lp == null) return;
    if (langPref != null && langPref.isNotEmpty) {
      lp.setLocale(langPref);
    } else if (_user?.country != null) {
      lp.setLocaleFromCountry(_user!.country);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      // ── Connection-level errors (no response from server) ──────────────────
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Please check your internet connection.';
      }

      final statusCode = error.response?.statusCode;

      // ── Try to extract the real error message from the server body ─────────
      final data = error.response?.data;
      if (data is Map && data['error'] != null && data['error'].toString().isNotEmpty) {
        return data['error'].toString();
      }

      // ── Status-code specific fallbacks ─────────────────────────────────────
      if (statusCode == 401) return 'Wrong username or password.';
      if (statusCode == 409) return 'An account with this email or username already exists.';
      if (statusCode == 400) return 'Please check your information and try again.';
      if (statusCode != null && statusCode >= 500) {
        return 'The server encountered an error. Please try again in a moment.';
      }

      return 'Something went wrong. Please try again.';
    }

    // Fallback for non-Dio errors
    final msg = error.toString();
    if (msg.contains('401')) return 'Wrong username or password.';
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach the server. Please check your internet connection.';
    }
    return msg;
  }
}
