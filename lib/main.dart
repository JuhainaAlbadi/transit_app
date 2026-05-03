import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/benchmark_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:transit_app/screens/map_screen.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

const _primary = Color(0xFF1565C0);
const _darkBg = Color(0xFF0D1117);
const _darkSurface = Color(0xFF161B22);

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = _DevHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(MyApp(showOnboarding: !onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'AI Public Transport Assistant',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: _primary,
            unselectedItemColor: Color(0xFF90A4AE),
            elevation: 8,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _primary,
            brightness: Brightness.dark,
          ).copyWith(
            surface: _darkSurface,
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: _darkBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: _darkSurface,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardTheme: CardThemeData(
            color: _darkSurface,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: _darkSurface,
            selectedItemColor: Color(0xFF58A6FF),
            unselectedItemColor: Color(0xFF8B949E),
            elevation: 8,
          ),
        ),
        initialRoute: showOnboarding ? '/onboarding' : '/home',
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const MainScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(),
    const BenchmarkScreen(),
    const MapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = themeModeNotifier.value == ThemeMode.dark;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.train), label: 'Departures'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat), label: 'AI Assistant'),
          BottomNavigationBarItem(
              icon: Icon(Icons.speed), label: 'Benchmark'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'theme_toggle',
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          themeModeNotifier.value =
              isDark ? ThemeMode.light : ThemeMode.dark;
          setState(() {});
        },
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: Colors.white,
        ),
      ),
    );
  }
}
