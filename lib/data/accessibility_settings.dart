import 'package:flutter/foundation.dart';

import 'app_database.dart';

class AccessibilitySettings extends ChangeNotifier {
  AccessibilitySettings._();

  static final AccessibilitySettings instance = AccessibilitySettings._();

  static const defaultFontScale = 1.0;
  static const minFontScale = 0.9;
  static const maxFontScale = 1.5;

  double _fontScale = defaultFontScale;

  double get fontScale => _fontScale;

  Future<void> load() async {
    _fontScale = await AppDatabase.instance.fontScale() ?? defaultFontScale;
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    final fontScale = value.clamp(minFontScale, maxFontScale).toDouble();
    if (_fontScale == fontScale) return;
    _fontScale = fontScale;
    notifyListeners();
    await AppDatabase.instance.setFontScale(fontScale);
  }
}