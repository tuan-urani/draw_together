import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class AppShared {
  static const String keyName = 'app';
  static const String keyBox = '${keyName}_shared';

  static const String _keyFcmToken = '${keyName}_keyFCMToken';
  static const String _keyTokenValue = '${keyName}_keyTokenValue';
  static const String _keyLanguageCode = '${keyName}_keyLanguageCode';

  final SharedPreferences _prefs;
  final StreamController<String?> _tokenValueController =
      StreamController<String?>.broadcast();

  AppShared(this._prefs);

  Future<void> setTokenFcm(String firebaseToken) async {
    await _prefs.setString(_keyFcmToken, firebaseToken);
  }

  String? getTokenFcm() => _prefs.getString(_keyFcmToken);

  Future<void> setLanguageCode(String languageCode) async {
    await _prefs.setString(_keyLanguageCode, languageCode);
  }

  String? getLanguageCode() => _prefs.getString(_keyLanguageCode);

  Future<void> setTokenValue(String tokenValue) async {
    await _prefs.setString(_keyTokenValue, tokenValue);
    _tokenValueController.add(tokenValue);
  }

  String? getTokenValue() => _prefs.getString(_keyTokenValue);

  Stream<String?> watchTokenValue() => _tokenValueController.stream;

  Future<int> clear() async {
    await _prefs.remove(_keyFcmToken);
    await _prefs.remove(_keyTokenValue);
    await _prefs.remove(_keyLanguageCode);
    _tokenValueController.add(null);
    return 1;
  }

  void dispose() {
    _tokenValueController.close();
  }
}
