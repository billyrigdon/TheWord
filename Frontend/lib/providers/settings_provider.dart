// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/settings_service.dart';
//
// class SettingsProvider with ChangeNotifier {
//   MaterialColor? _currentColor;
//   MaterialColor? _highlightColor;
//   ThemeMode _currentThemeMode;
//   String? _currentTranslationId;
//   String? _currentTranslationName;
//   bool _isLoggedIn = false;
//
//   final SettingsService settingsService = SettingsService();
//
//   SettingsProvider()
//       : _currentColor = null,
//         _highlightColor = null,
//         _currentThemeMode = ThemeMode.dark,
//         _currentTranslationId = 'bba9f40183526463-01',
//         _currentTranslationName = 'Berean Standard Bible' {
//     loadSettings();
//   }
//
//   MaterialColor? get currentColor => _currentColor;
//   MaterialColor? get highlightColor => _highlightColor;
//   ThemeMode get currentThemeMode => _currentThemeMode;
//   String? get currentTranslationId => _currentTranslationId;
//   String? get currentTranslationName => _currentTranslationName;
//   bool get isLoggedIn => _isLoggedIn;
//
//   Future<void> loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     _currentColor = await settingsService.loadColor();
//     _highlightColor = await settingsService.loadHighlightColor();
//     _currentThemeMode = await settingsService.loadThemeMode();
//     var translation = await settingsService.loadTranslation();
//     _currentTranslationId = translation['id'];
//     _currentTranslationName = translation['name'];
//     final token = prefs.getString('token');
//     final tokenExpiry = prefs.getInt('tokenExpiry') ?? 0;
//     if (token != null && tokenExpiry > DateTime.now().millisecondsSinceEpoch) {
//       _isLoggedIn = true;
//       await fetchUserSettingsFromBackend(token);
//     } else {
//       _isLoggedIn = false;
//     }
//     notifyListeners();
//   }
//
//   Future<void> fetchUserSettingsFromBackend(String token) async {
//     final settings = await settingsService.fetchUserSettings(token);
//     if (settings != null) {
//       _currentColor = settings['primary_color'];
//       _highlightColor = settings['highlight_color'];
//       _currentThemeMode = settings['dark_mode'] ? ThemeMode.dark : ThemeMode.light;
//     }
//     notifyListeners();
//   }
//
//   Future<void> updateUserSettingsOnBackend() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     if (token != null) {
//       await settingsService.updateUserSettings(
//         token,
//         _currentColor!,
//         _highlightColor!,
//         _currentThemeMode == ThemeMode.dark,
//       );
//     }
//   }
//
//   void updateColor(MaterialColor color) {
//     _currentColor = color;
//     settingsService.saveColor(color);
//     updateUserSettingsOnBackend();
//     notifyListeners();
//   }
//
//   void updateHighlightColor(MaterialColor color) {
//     _highlightColor = color;
//     settingsService.saveHighlightColor(color);
//     updateUserSettingsOnBackend();
//     notifyListeners();
//   }
//
//   void updateThemeMode(ThemeMode themeMode) {
//     _currentThemeMode = themeMode;
//     settingsService.saveThemeMode(themeMode);
//     updateUserSettingsOnBackend();
//     notifyListeners();
//   }
//
//   void updateTranslation(String translationId, String translationName) {
//     _currentTranslationId = translationId;
//     _currentTranslationName = translationName;
//     settingsService.saveTranslation(translationId, translationName);
//     notifyListeners();
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';



class SettingsProvider with ChangeNotifier {
  MaterialColor? _currentColor;
  MaterialColor? _highlightColor;
  ThemeMode _currentThemeMode;
  String? _currentTranslationId;
  String? _currentTranslationName;
  bool _isLoggedIn = false;
  bool _isPublicProfile = false;
  List<dynamic> _translations = [];

  final SettingsService settingsService = SettingsService();

  SettingsProvider()
      : _currentColor = null,
        _highlightColor = null,
        _currentThemeMode = ThemeMode.dark,
        _currentTranslationId = 'bba9f40183526463-01',
        _currentTranslationName = 'Berean Standard Bible' {
    loadSettings();
  }

  MaterialColor? get currentColor => _currentColor;
  MaterialColor? get highlightColor => _highlightColor;
  ThemeMode get currentThemeMode => _currentThemeMode;
  String? get currentTranslationId => _currentTranslationId;
  String? get currentTranslationName => _currentTranslationName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPublicProfile => _isPublicProfile;
  List<dynamic> get translations => _translations;

  Color getFontColor(MaterialColor color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);

    if (brightness == Brightness.dark) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentColor = _parseColor(prefs.getInt('primaryColor') ?? Colors.black.value);
    _highlightColor = _parseColor(prefs.getInt('highlightColor') ?? Colors.yellow.value);
    _currentThemeMode = await settingsService.loadThemeMode();
    var translation = await settingsService.loadTranslation();
    _currentTranslationId = translation['id'];
    _currentTranslationName = translation['name'];
    final token = prefs.getString('token');
    final tokenExpiry = prefs.getInt('tokenExpiry') ?? 0;
    if (token != null && tokenExpiry > DateTime.now().millisecondsSinceEpoch) {
      _isLoggedIn = true;
      await fetchUserSettingsFromBackend(token);
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  Future<void> fetchUserSettingsFromBackend(String token) async {
    final settings = await settingsService.fetchUserSettings(token);
    print(settings.toString());
    if (settings != null) {
      _currentColor = _parseColor(settings['primary_color']);
      _highlightColor = _parseColor(settings['highlight_color']);
      _currentThemeMode = settings['dark_mode'] ? ThemeMode.dark : ThemeMode.light;
      _isPublicProfile = settings['public_profile'];
    }
    notifyListeners();
  }

  Future<void> fetchTranslations() async {
    if (_translations.isEmpty) {
      _translations = await settingsService.fetchTranslations();
    }
  }

  Future<void> updateUserSettingsOnBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      await settingsService.updateUserSettings(
        token,
        _currentColor!.value,
        _highlightColor!.value,
        _currentThemeMode == ThemeMode.dark,
        _isPublicProfile,
        _currentTranslationId!,
        _currentTranslationName!,
      );
    }
  }

  void updateColor(MaterialColor color) {
    _currentColor = color;
    settingsService.saveColor(color);
    notifyListeners();
  }

  void updateHighlightColor(MaterialColor color) {
    print(color.value);
    _highlightColor = color;
    settingsService.saveHighlightColor(color);
    notifyListeners();
  }

  void updateThemeMode(ThemeMode themeMode) {
    _currentThemeMode = themeMode;
    settingsService.saveThemeMode(themeMode);
    notifyListeners();
  }

  void updateTranslation(String translationId, String translationName) {
    _currentTranslationId = translationId;
    _currentTranslationName = translationName;
    settingsService.saveTranslation(translationId, translationName);
    notifyListeners();
  }

  void togglePublicProfile(value) {
    _isPublicProfile = value;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentColor = null;
    _highlightColor = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  MaterialColor _parseColor(int colorValue) {
    return MaterialColor(colorValue, {
      50: Color(colorValue).withOpacity(0.1),
      100: Color(colorValue).withOpacity(0.2),
      200: Color(colorValue).withOpacity(0.3),
      300: Color(colorValue).withOpacity(0.4),
      400: Color(colorValue).withOpacity(0.5),
      500: Color(colorValue).withOpacity(0.6),
      600: Color(colorValue).withOpacity(0.7),
      700: Color(colorValue).withOpacity(0.8),
      800: Color(colorValue).withOpacity(0.9),
      900: Color(colorValue),
    });
  }
}



