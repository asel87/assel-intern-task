import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _boxName = 'settings';
  static const _key = 'themeMode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_key) as String?;
    mode.value = _decode(saved);
    mode.addListener(() {
      box.put(_key, _encode(mode.value));
    });
  }

  void toggle() {
    final next = switch (mode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    mode.value = next;
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
