import 'package:flutter/material.dart';
import '../../core/widgets/platform_adaptive.dart';
import 'package:provider/provider.dart';

import '../../core/db/quran_repository.dart';
import '../../core/models/ayah.dart';
import '../reader/quran_page_screen.dart';
import '../../core/models/surah.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Ayah> _results = [];
  bool _loading = false;
  bool _searchSurah = true; // only surah search retained
  List<Surah> _surahResults = [];

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() => _loading = true);
    final repo = context.read<QuranRepository>();
    // Only surah search is supported now.
    final all = await repo.getSurahs();
    final q = trimmed;
    final filtered = all.where((s) {
      final ar = s.nameAr;
      final en = s.nameEn ?? '';
      return ar.contains(q) || en.toLowerCase().contains(q.toLowerCase());
    }).toList();
    setState(() {
      _surahResults = filtered;
      _results = [];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: platformAppBar(
        context: context,
        title: const Text('بحث في القرآن'),
      ),
      body: Column(
        children: [
          // Only surah search retained; no toggle needed.
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اكتب كلمة أو جملة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _searchSurah
                ? ListView.separated(
                    itemCount: _surahResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = _surahResults[index];
                      return ListTile(
                        title: Text(
                          s.nameAr,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 20),
                        ),
                        subtitle: Text('${s.ayahCount} آية'),
                        trailing: Text('${s.id}'),
                        onTap: () async {
                          final repo = context.read<QuranRepository>();
                          final navigator = Navigator.of(context);
                          final page = await repo.getFirstPageOfSurah(s.id);
                          if (!mounted) return;
                          // Open reader at the surah's first page
                          await navigator.push(platformPageRoute(
                            builder: (_) => QuranPageScreen(initialPage: page),
                          ));
                        },
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final ayah = _results[index];
                      return ListTile(
                        title: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(ayah.textAr),
                        ),
                        subtitle: Text('سورة ${ayah.surahId}، آية ${ayah.ayahNumber}'),
                        // يمكن لاحقًا الانتقال مباشرة للسورة والآية
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

