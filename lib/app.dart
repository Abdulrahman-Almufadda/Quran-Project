import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/db/database_helper.dart';
import 'core/db/quran_repository.dart';
import 'features/reader/quran_page_screen.dart';
import 'features/splash/splash_screen.dart';

const String _kLastReadPageKey = 'last_read_page';

/// Loads last read page from storage and opens the reader directly.
class ReaderEntryScreen extends StatelessWidget {
  const ReaderEntryScreen({super.key});

  Future<int> _getLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kLastReadPageKey) ?? 1;
    // ignore: avoid_print
    print('[Reader] Loaded last page=$v');
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getLastPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final initialPage = (snapshot.data ?? 1).clamp(1, QuranRepository.totalPages);
        return QuranPageScreen(
          initialPage: initialPage,
          showBackButton: false,
        );
      },
    );
  }
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        Provider<DatabaseHelper>(
          create: (_) => DatabaseHelper(),
        ),
        ProxyProvider<DatabaseHelper, QuranRepository>(
          update: (_, dbHelper, __) => QuranRepository(dbHelper),
        ),
      ],
            child: Consumer<ThemeNotifier>(
        builder: (_, themeNotifier, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'القرآن الكريم',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

