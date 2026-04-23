import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/platform_adaptive.dart';
import '../reader/quran_page_screen.dart';

const String _kLastReadPageKey = 'last_read_page';

class _Ayah {
  final String text;
  final String surah;
  final String number;
  const _Ayah({required this.text, required this.surah, required this.number});
}

const List<_Ayah> _curatedAyahs = [
  _Ayah(
    text: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    surah: 'الرعد',
    number: '٢٨',
  ),
  _Ayah(
    text: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ۚ إِنَّ اللَّهَ بَالِغُ أَمْرِهِ',
    surah: 'الطلاق',
    number: '٣',
  ),
  _Ayah(
    text: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    surah: 'الشرح',
    number: '٥-٦',
  ),
  _Ayah(
    text: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
    surah: 'البقرة',
    number: '٢٨٦',
  ),
  _Ayah(
    text:
        'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا',
    surah: 'الزمر',
    number: '٥٣',
  ),
  _Ayah(
    text: 'إِنَّا نَحْنُ نَزَّلْنَا الذِّكْرَ وَإِنَّا لَهُ لَحَافِظُونَ',
    surah: 'الحجر',
    number: '٩',
  ),
  _Ayah(
    text: 'وَلَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ',
    surah: 'إبراهيم',
    number: '٧',
  ),
  _Ayah(
    text: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    surah: 'البقرة',
    number: '١٥٢',
  ),
  _Ayah(
    text:
        'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
    surah: 'البقرة',
    number: '١٨٦',
  ),
  _Ayah(
    text: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    surah: 'آل عمران',
    number: '١٧٣',
  ),
  _Ayah(
    text: 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    surah: 'البقرة',
    number: '١٥٣',
  ),
  _Ayah(
    text: 'وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ',
    surah: 'البقرة',
    number: '٢١٦',
  ),
];

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with WidgetsBindingObserver {
  late final _Ayah _ayah;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _ayah = _curatedAyahs[Random().nextInt(_curatedAyahs.length)];
    WidgetsBinding.instance.addObserver(this);
    _loadLastPage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadLastPage();
  }

  Future<void> _loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastReadPageKey) ?? 1;
    if (mounted) setState(() => _lastPage = saved.clamp(1, 604));
  }

  void _goToLastPage() {
    Navigator.of(context).pushReplacement(
      platformPageRoute(
        builder: (_) => QuranPageScreen(initialPage: _lastPage, showBackButton: false),
      ),
    );
  }

  void _goToFirstPage() {
    Navigator.of(context).pushReplacement(
      platformPageRoute(
        builder: (_) => const QuranPageScreen(initialPage: 1, showBackButton: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F0E6);
    final gold = isDark ? const Color(0xFFD4A84B) : const Color(0xFFB8860B);
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Title
                Text(
                  'القرآن الكريم',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1.5, color: gold.withValues(alpha: 0.4)),
                const Spacer(),
                // Ayah card
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gold.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      Text(
                        '❝',
                        style: TextStyle(fontSize: 28, color: gold.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _ayah.text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          height: 1.9,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: gold.withValues(alpha: 0.25)),
                      const SizedBox(height: 14),
                      Text(
                        'سورة ${_ayah.surah} — الآية ${_ayah.number}',
                        style: GoogleFonts.amiri(
                          fontSize: 15,
                          color: gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Primary button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _goToLastPage,
                    icon: const Icon(Icons.bookmark_rounded),
                    label: Text(
                      'اذهب لآخر صفحة مقروءة',
                      style: GoogleFonts.amiri(fontSize: 18),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goToFirstPage,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(
                      'ابدأ من أول المصحف',
                      style: GoogleFonts.amiri(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: BorderSide(color: gold.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
