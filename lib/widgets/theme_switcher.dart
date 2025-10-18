import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeSwitcherAction extends StatelessWidget {
  const ThemeSwitcherAction({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.I,
      builder: (context, _) {
        final isDark = ThemeService.I.mode == ThemeMode.dark;

        return IconButton.filledTonal(
          tooltip: 'Тема: ${isDark ? 'Тёмная' : 'Светлая'}',
          icon:
              Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
          onPressed: () {
            if (isDark) {
              do {
                ThemeService.I.toggle();
              } while (ThemeService.I.mode != ThemeMode.light);
            } else {
              do {
                ThemeService.I.toggle();
              } while (ThemeService.I.mode != ThemeMode.dark);
            }
          },
        );
      },
    );
  }
}
