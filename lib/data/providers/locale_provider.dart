import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/widgets/country_customization.dart';

/// Holds and persists the current app locale.
///
/// - Auto-switched when a teacher selects their country.
/// - Persisted to SharedPreferences so it survives restarts.
/// - Notify listeners so [MaterialApp.locale] updates reactively.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  /// Human-readable name of the current language (in that language).
  String get languageName {
    switch (_locale.languageCode) {
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'am':
        return 'አማርኛ';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'English';
    }
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once at startup to restore the saved locale.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && _isSupported(saved)) {
        _locale = Locale(saved);
        notifyListeners();
      }
    } catch (_) {
      // If prefs fail, stay on English — never crash startup.
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Set locale by language code (e.g. 'pt', 'fr', 'en').
  /// Ignores unsupported codes rather than crashing.
  Future<void> setLocale(String languageCode) async {
    if (!_isSupported(languageCode)) return;
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
    } catch (_) {
      // Persist failure is non-fatal — locale is still active in memory.
    }
  }

  /// Auto-select locale based on a country name.
  /// Uses [CountryCustomization.getLanguageCode].
  Future<void> setLocaleFromCountry(String? country) async {
    if (country == null || country.isEmpty) return;
    final code = CountryCustomization.getLanguageCode(country);
    await setLocale(code);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static const _supported = {'en', 'pt', 'fr', 'am', 'sw'};

  bool _isSupported(String code) => _supported.contains(code);
}
