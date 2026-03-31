import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CountryCustomization {
  static const List<String> _customizedCountries = [
    'Ethiopia',
    'Senegal',
    'Tanzania',
    'Seychelles',
  ];

  /// Returns true if the user's country is customized.
  static bool isCustomized(String? country) {
    if (country == null) return false;
    return _customizedCountries.contains(country);
  }

  /// Returns a primary accent color extracted from the country's flag.
  /// Falls back to the app's default primary color if not customized.
  static Color getAccentColor(String? country) {
    switch (country) {
      case 'Ethiopia':
        return const Color(0xFF009A44); // Green
      case 'Senegal':
        return const Color(0xFFE3122C); // Red
      case 'Tanzania':
        return const Color(0xFF00A3DD); // Blue
      case 'Seychelles':
        return const Color(0xFF003D88); // Dark Blue
      default:
        return AppTheme.primaryColor;
    }
  }
}
