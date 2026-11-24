import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_strings.dart';

/// Menyimpan pilihan bahasa antarmuka di perangkat (tanpa mengubah database).
class LocaleProvider extends ChangeNotifier {
  LocaleProvider();

  static const String _storageKey = 'barberly_language';

  String _languageCode = 'id';
  SharedPreferences? _preferences;

  String get languageCode => _languageCode;
  bool get isEnglish => _languageCode == 'en';

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences!.getString(_storageKey);

    if (saved == 'id' || saved == 'en') {
      _languageCode = saved!;
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'id' && code != 'en') return;
    if (_languageCode == code) return;

    _languageCode = code;
    notifyListeners();

    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_storageKey, code);
  }

  String translate(String key) => AppStrings.of(_languageCode, key);
}
