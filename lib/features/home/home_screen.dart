import 'package:flutter/material.dart';
import '../../core/widgets/platform_adaptive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/db/quran_repository.dart';
import '../../core/models/surah.dart';
import '../reader/quran_page_screen.dart';
import '../search/search_screen.dart';
import '../bookmarks/bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Surah> _surahs = [];
  List<Surah> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final repo = context.read<QuranRepository>();
    repo.getSurahs().then((list) {
      setState(() {
        _surahs = list;
        _filtered = list;
        _loading = false;
      });
    }).catchError((_) {
      setState(() {
        _surahs = [];
        _filtered = [];
        _loading = false;
      });
    });
  }

  void _onSearchChanged(String q) {
    final t = q.trim();
    if (t.isEmpty) {
      setState(() => _filtered = _surahs);
      return;
    }
    final lower = t.toLowerCase();
    setState(() {
      _filtered = _surahs.where((s) {
        final ar = s.nameAr;
        final en = s.nameEn ?? '';
        return ar.contains(t) || en.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: platformAppBar(
        context: context,
        title: Text(
          'القرآن الكريم',
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'قراءة من أول المصحف',
            onPressed: () {
              Navigator.of(context).push(
                platformPageRoute(builder: (_) => const QuranPageScreen(initialPage: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(platformPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.of(context).push(platformPageRoute(builder: (_) => const BookmarksScreen()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سورة...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchChanged,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('لا توجد بيانات للسور'))
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final surah = _filtered[index];
                            return ListTile(
                              title: Text(
                                surah.nameAr,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.amiri(fontSize: 22),
                              ),
                              subtitle: Text(
                                '${surah.ayahCount} آية',
                                style: GoogleFonts.amiri(fontSize: 16),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${surah.id}',
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final repo = context.read<QuranRepository>();
                                final page = await repo.getFirstPageOfSurah(surah.id);
                                if (!context.mounted) return;
                                Navigator.of(context).push(platformPageRoute(builder: (_) => QuranPageScreen(initialPage: page)));
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}


