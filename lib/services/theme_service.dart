import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService I = ThemeService._();

  static const _boxName = 'settings';
  static const _key = 'themeMode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _mode = _decode(_box.get(_key) as String?);

    addListener(() => _box.put(_key, _encode(_mode)));
  }

  void toggle() {
    _mode = switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
  }

  void setMode(ThemeMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
  }

  String _encode(ThemeMode m) => switch (m) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  ThemeMode _decode(String? s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
