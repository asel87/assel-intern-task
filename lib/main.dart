import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/home_page.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ThemeService.I.init(); // читаем сохранённый режим темы
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.I, // перестраиваемся при смене темы
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Volleyball Inventory',
          theme: _lightShopTheme,
          darkTheme: _darkShopTheme,
          themeMode: ThemeService.I.mode, // system / light / dark
          home: const HomePage(),
        );
      },
    );
  }
}

/// ---------- LIGHT THEME: магазинный стиль ----------
final _lightShopTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1256C5),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F5F7),
  textTheme: ThemeData.light().textTheme.copyWith(
        displaySmall: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black87,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 3,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    prefixIconColor: Colors.black45,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      padding: const MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: const MaterialStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 4,
    backgroundColor: Color(0xFFFFC400),
    foregroundColor: Colors.black,
    shape: StadiumBorder(),
  ),
  chipTheme: ChipThemeData(
    side: const BorderSide(color: Color(0xFFE6E8EC)),
    backgroundColor: Colors.white,
    labelStyle: const TextStyle(color: Color(0xFF2C2E33)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0.5,
    pressElevation: 0.5,
    shadowColor: Colors.black12,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: Color(0xFF22252E),
    iconTheme: MaterialStatePropertyAll(IconThemeData(size: 22)),
    labelTextStyle:
        MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return const Color(0xFFEFF6FF);
        }
        return const Color(0xFFF2F6FF);
      }),
      foregroundColor: const MaterialStatePropertyAll<Color>(Color(0xFF0E3E91)),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      padding: const MaterialStatePropertyAll(EdgeInsets.all(8)),
    ),
  ),
);

/// ---------- DARK THEME: глубокий графит + синие акценты ----------
final _darkShopTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6FA8FF),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F141B),
  textTheme: ThemeData.dark().textTheme.copyWith(
        displaySmall: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      ),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
  cardTheme: CardThemeData(
    elevation: 4,
    shadowColor: Colors.black.withOpacity(.35),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    color: const Color(0xFF171C25),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF171C25),
    isDense: true,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    prefixIconColor: Colors.white70,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFFC400),
    foregroundColor: Colors.black,
    shape: StadiumBorder(),
  ),
  chipTheme: ChipThemeData(
    side: const BorderSide(color: Color(0xFF262D38)),
    backgroundColor: const Color(0xFF1B2230),
    labelStyle: const TextStyle(color: Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.transparent,
    indicatorColor: Color(0xFF2A3140),
    iconTheme: MaterialStatePropertyAll(IconThemeData(size: 22)),
    labelTextStyle:
        MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
  ),
);
