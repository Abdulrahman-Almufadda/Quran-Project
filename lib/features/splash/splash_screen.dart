import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/platform_adaptive.dart';
import '../reader/quran_page_screen.dart';

/// Simple splash/loading screen that shows the provided icon and then
/// hands off to the reader entry screen which restores the last-read page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _hasIcon = false;

  @override
  void initState() {
    super.initState();
    // Probe whether the bundled icon exists; this avoids hard failures when
    // the asset hasn't been added yet. Then show splash for a short duration.
    rootBundle.load('assets/quran_icon.png').then((_) {
      _hasIcon = true;
    }).catchError((_) {
      _hasIcon = false;
    }).whenComplete(() {
      if (!mounted) return;
      setState(() {});
      _timer = Timer(const Duration(milliseconds: 800), _goNext);
    });
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('last_read_page') ?? 1;
      final initial = (saved).clamp(1, 604);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(platformPageRoute(builder: (_) => QuranPageScreen(initialPage: initial)));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(platformPageRoute(builder: (_) => const QuranPageScreen()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size.shortestSide * 0.45;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasIcon)
                Image.asset(
                  'assets/quran_icon.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                )
              else
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(size * 0.12),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    size: size * 0.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'القرآن الكريم',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
