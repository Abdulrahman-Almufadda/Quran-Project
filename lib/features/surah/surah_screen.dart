import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../core/widgets/platform_adaptive.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/db/quran_repository.dart';
import '../../core/models/ayah.dart';
import '../../core/theme/app_theme.dart';

class SurahScreen extends StatefulWidget {
  final int surahId;
  final String surahName;

  const SurahScreen({
    super.key,
    required this.surahId,
    required this.surahName,
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  late Future<List<Ayah>> _futureAyahs;

  @override
  void initState() {
    super.initState();
    final repo = context.read<QuranRepository>();
    _futureAyahs = repo.getAyahsBySurah(widget.surahId);
  }

  Future<void> _showAyahOptions(Ayah ayah) async {
    final repo = context.read<QuranRepository>();
    final isBookmarked =
        await repo.isBookmarked(ayah.surahId, ayah.ayahNumber);

    if (!mounted) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Show a native CupertinoActionSheet on iOS
      final actions = <CupertinoActionSheetAction>[
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: ayah.textAr));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم النسخ')),
            );
          },
          child: const Text('نسخ'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            // share action placeholder
          },
          child: const Text('مشاركة'),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(context);
            if (isBookmarked) {
              await repo.removeBookmark(ayah.surahId, ayah.ayahNumber);
            } else {
              await repo.addBookmark(ayah.surahId, ayah.ayahNumber);
            }
            if (mounted) setState(() {});
          },
          child: Text(isBookmarked ? 'إزالة من العلامات المرجعية' : 'إضافة علامة مرجعية'),
        ),
      ];

      showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          actions: actions,
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ),
      );
      return;
    }

    // Fallback: material bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('نسخ'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: ayah.textAr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('مشاركة'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                title: Text(
                  isBookmarked
                      ? 'إزالة من العلامات المرجعية'
                      : 'إضافة علامة مرجعية',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (isBookmarked) {
                    await repo.removeBookmark(ayah.surahId, ayah.ayahNumber);
                  } else {
                    await repo.addBookmark(ayah.surahId, ayah.ayahNumber);
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = isDark ? AppTheme.ayahNumberGoldLight : AppTheme.ayahNumberGold;

    return Scaffold(
      appBar: platformAppBar(
        context: context,
        title: Text(
          widget.surahName,
          style: AppTheme.surahTitleStyle(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _futureAyahs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في تحميل الآيات'));
          }

          final ayahs = snapshot.data ?? [];
          if (ayahs.isEmpty) {
            return const Center(child: Text('لا توجد آيات'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _SurahHeader(
                surahName: widget.surahName,
                surahOrder: widget.surahId,
                ayahCount: ayahs.length,
              ),
              if (widget.surahId != 1 && widget.surahId != 9) ...[
                const SizedBox(height: 20),
                _Basmalah(),
                const SizedBox(height: 24),
              ],
              ...ayahs.map((ayah) => _AyahRow(
                    ayah: ayah,
                    goldColor: goldColor,
                    onTap: () => _showAyahOptions(ayah),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final String surahName;
  final int surahOrder;
  final int ayahCount;

  const _SurahHeader({
    required this.surahName,
    required this.surahOrder,
    required this.ayahCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.ayahNumberGoldLight : AppTheme.ayahNumberGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'سورة $surahName',
            style: AppTheme.surahTitleStyle(context),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaChip(label: 'ترتيبها', value: '$surahOrder'),
              const SizedBox(width: 16),
              _MetaChip(label: 'آياتها', value: '$ayahCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = isDark ? AppTheme.ayahNumberGoldLight : AppTheme.ayahNumberGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.5)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 14,
          color: goldColor,
          fontWeight: FontWeight.w600,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _Basmalah extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const text = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
    return Center(
      child: Text(
        text,
        style: AppTheme.arabicBasmalahStyle(context),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _AyahRow extends StatelessWidget {
  final Ayah ayah;
  final Color goldColor;
  final VoidCallback onTap;

  const _AyahRow({
    required this.ayah,
    required this.goldColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final verseStyle = AppTheme.arabicVerseStyle(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  textAlign: TextAlign.justify,
                  text: _buildHighlightedSpans(context, ayah.textAr, verseStyle),
                ),
              ),
              const SizedBox(width: 10),
              _AyahNumberBadge(number: ayah.ayahNumber, goldColor: goldColor),
            ],
          ),
        ),
      ),
    );
  }

  InlineSpan _buildHighlightedSpans(
    BuildContext context,
    String text,
    TextStyle baseStyle,
  ) {
    // Longer patterns first to avoid overlapping (e.g. اللَّهِ before اللَّه)
    const highlightPatterns = [
      'اللَّهِ',
      'اللَّهَ',
      'اللَّهُ',
      'لِلَّهِ',
      'رَبَّنَا',
      'اللَّه',
    ];

    final redColor = AppTheme.quranHighlightRed;

    final spans = <InlineSpan>[];
    int start = 0;

    while (start < text.length) {
      int? earliestStart;
      String? longestPattern;

      for (final pattern in highlightPatterns) {
        final idx = text.indexOf(pattern, start);
        if (idx == -1) continue;
        if (earliestStart == null || idx < earliestStart) {
          earliestStart = idx;
          longestPattern = pattern;
        } else if (idx == earliestStart &&
            (longestPattern == null || pattern.length > longestPattern.length)) {
          longestPattern = pattern;
        }
      }

      if (earliestStart == null || longestPattern == null) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (earliestStart > start) {
        spans.add(TextSpan(
          text: text.substring(start, earliestStart),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: longestPattern,
        style: baseStyle.copyWith(
          color: redColor,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = earliestStart + longestPattern.length;
    }

    return TextSpan(children: spans);
  }
}

class _AyahNumberBadge extends StatelessWidget {
  final int number;
  final Color goldColor;

  const _AyahNumberBadge({
    required this.number,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: goldColor, width: 1.5),
        color: goldColor.withOpacity(0.12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: goldColor,
        ),
      ),
    );
  }
}
