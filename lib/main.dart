import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'providers/settings_provider.dart';
import 'screens/developer_messages_screen.dart';
import 'screens/genre_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();
  if (kDebugMode) {
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['1bd75e3b13a395d2a82ff51b513f30f4'],
      ),
    );
  }
  runApp(const ProviderScope(child: StockMemoApp()));
}

class StockMemoApp extends ConsumerWidget {
  const StockMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.value?.themeMode ?? ThemeMode.system;

    return MaterialApp(
      title: 'StockMemo',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1AF64),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.zenMaruGothicTextTheme(),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1AF64),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.zenMaruGothicTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/genres': (_) => const GenreSelectionScreen(),
        '/inventory': (_) => const InventoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/developer_messages': (_) => const DeveloperMessagesScreen(),
      },
    );
  }
}
