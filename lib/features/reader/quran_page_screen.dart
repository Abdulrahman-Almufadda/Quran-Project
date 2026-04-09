import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../../core/widgets/platform_adaptive.dart';

import '../../core/db/quran_repository.dart';
import '../../core/models/ayah.dart';
import '../../core/theme/app_theme.dart';
import '../../core/svg/svg_loader.dart';
import '../search/search_screen.dart';

const String _kLastReadPageKey = 'last_read_page';

/// Reads the Quran by Mushaf pages (1–604). Verses flow together with inline ayah numbers.
class QuranPageScreen extends StatefulWidget {
  final int initialPage;
  final bool showBackButton;

  const QuranPageScreen({
    super.key,
    this.initialPage = 1,
    this.showBackButton = true,
  });

  @override
  State<QuranPageScreen> createState() => _QuranPageScreenState();
}

class _QuranPageScreenState extends State<QuranPageScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  // No zoom state: pages render at their natural size and fill the viewport.

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: (widget.initialPage - 1).clamp(0, QuranRepository.totalPages - 1),
    );
    // Ensure the controller is positioned correctly after first frame so
    // the bottom indicator and other listeners reflect the initial page
    // immediately (avoids briefly showing page 1 until layout completes).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = (widget.initialPage - 1).clamp(0, QuranRepository.totalPages - 1);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(target);
      }
    });
    WidgetsBinding.instance.addObserver(this);
    // Additionally, attempt to restore from SharedPreferences here as a
    // fallback in case ReaderEntryScreen didn't provide the correct value
    // (covers edge cases where storage was written after the previous run
    // or lifecycle events were not delivered).
    _restoreSavedPage();
  }

  Future<void> _restoreSavedPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kLastReadPageKey) ?? 1;
      // ignore: avoid_print
      print('[Reader] _restoreSavedPage found=$saved initial=${widget.initialPage}');
      final target = (saved).clamp(1, QuranRepository.totalPages);
      final targetIndex = target - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      } else {
        // if not yet attached, set the controller's initial page by
        // creating a new controller and replacing the old one.
        _pageController.dispose();
        _pageController = PageController(initialPage: targetIndex);
        setState(() {});
      }
    } catch (e) {
      // ignore errors
    }
  }

  void _showGoToPage(BuildContext context) {
  final c = _pageController;
    if (!c.hasClients) return;
    final current = (c.page ?? 0).round() + 1;
    final controller = TextEditingController(text: '$current');
    showPlatformDialog<void>(
      context: context,
      builder: (ctx) {
        // Use Cupertino-style dialog on iOS and AlertDialog elsewhere
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return CupertinoAlertDialog(
            title: const Text('انتقل إلى صفحة'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: CupertinoTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                placeholder: '١ - ٦٠٤',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final page = (int.tryParse(controller.text) ?? current).clamp(1, 604);
                  Navigator.pop(ctx);
                  c.jumpToPage(page - 1);
                  setState(() {});
                },
                isDefaultAction: true,
                child: const Text('انتقل'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('انتقل إلى صفحة'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '١ - ٦٠٤',
              suffixText: '/ 604',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final page = (int.tryParse(controller.text) ?? current).clamp(1, 604);
                Navigator.pop(ctx);
                c.jumpToPage(page - 1);
                setState(() {});
              },
              child: const Text('انتقل'),
            ),
          ],
        );
      },
    );
  }

  // Zoom removed per user request: no scale dialog.

  @override
  void dispose() {
    // Save current page when the reader is disposed so the next launch
    // restores the last-viewed page even if the user didn't trigger a
    // page change right before closing the app.
    try {
      final currentIndex = _pageController.hasClients
          ? (_pageController.page ?? (_pageController.initialPage)).round()
          : (widget.initialPage - 1);
      final current = (currentIndex + 1).clamp(1, QuranRepository.totalPages);
      _saveLastPage(current, 'dispose');
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist the last-read page when the app is backgrounded/paused so it
    // can be restored on the next cold start. This covers cases where
    // dispose() may not be called (system kills) or the user backgrounds the app.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      try {
        final currentIndex = _pageController.hasClients
            ? (_pageController.page ?? (_pageController.initialPage)).round()
            : (widget.initialPage - 1);
        final current = (currentIndex + 1).clamp(1, QuranRepository.totalPages);
        _saveLastPage(current, 'lifecycle');
      } catch (_) {}
    }
  }

  Future<void> _saveLastPage(int pageNumber, [String reason = 'unknown']) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setInt(_kLastReadPageKey, pageNumber);
    // small debug log to help investigate persistence issues
    // ignore: avoid_print
    print('[Reader] Saved last page=$pageNumber success=$ok reason=$reason');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: platformAppBar(
        context: context,
        title: const Text('القرآن الكريم'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'قائمة السور',
            onPressed: () async {
              final page = await Navigator.of(context).push<int>(
                platformPageRoute(
                  builder: (_) => const _SurahListScreen(),
                ),
              );
              if (page != null && mounted) {
                _pageController.jumpToPage(
                  (page - 1).clamp(0, QuranRepository.totalPages - 1),
                );
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () async {
              await Navigator.of(context).push(platformPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: QuranRepository.totalPages,
        onPageChanged: (int index) {
          setState(() {});
          _saveLastPage(index + 1, 'onPageChanged');
        },
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return _PageContent(pageNumber: pageNumber, pageController: _pageController);
        },
      ),
      bottomNavigationBar: _PageIndicator(
        controller: _pageController,
        onTap: () => _showGoToPage(context),
      ),
    );
  }

  // Zoom removed: no scale dialog.
}

class _PageIndicator extends StatelessWidget {
  final PageController controller;
  final VoidCallback onTap;

  const _PageIndicator({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasClients) return const SizedBox.shrink();
        final page = (controller.page ?? 0).round() + 1;
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ص $page',
                      style: AppTheme.surahTitleStyle(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${QuranRepository.totalPages}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageContent extends StatelessWidget {
  final int pageNumber;
  final PageController pageController;

  const _PageContent({required this.pageNumber, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: loadSvgForPage(pageNumber),
      builder: (context, svgSnapshot) {
        if (svgSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final svgStr = svgSnapshot.data;
        if (svgStr != null) {
          return InteractiveViewer(
            key: ValueKey('page_svg_$pageNumber'),
            minScale: 1.0,
            maxScale: 4.0,
            clipBehavior: Clip.none,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mq = MediaQuery.of(context);
                final topBar = kToolbarHeight + mq.padding.top;
                final bottomReserved = 64.0 + mq.padding.bottom;
                final viewportHeight = mq.size.height - topBar - bottomReserved;
                final availableWidth = constraints.maxWidth;

                // Render the SVG to fill the available reader area while
                // preserving aspect ratio. Using BoxFit.contain ensures the
                // entire page is visible and centered; it will scale up or
                // down to fit within the viewport without distortion.
                return SizedBox(
                  width: availableWidth,
                  height: viewportHeight,
                  child: SvgPicture.string(
                    svgStr,
                    allowDrawingOutsideViewBox: true,
                    width: availableWidth,
                    height: viewportHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                );
              },
            ),
          );
        }

        // Fallback for text (no extra padding/margins)
        final repo = context.read<QuranRepository>();
        return FutureBuilder<List<Ayah>>(
          future: repo.getAyahsByPage(pageNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'خطأ في تحميل الصفحة',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
            final ayahs = snapshot.data!;
            if (ayahs.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد آيات في هذه الصفحة',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            final isShortPage = pageNumber == 1 || ayahs.length <= 7;

            return isShortPage ? Center(child: _PageBody(ayahs: ayahs)) : _PageBody(ayahs: ayahs);
          },
        );
      },
    );
  }
}

class _PageBody extends StatefulWidget {
  final List<Ayah> ayahs;

  const _PageBody({required this.ayahs});

  @override
  State<_PageBody> createState() => _PageBodyState();
}

class _PageBodyState extends State<_PageBody> {
  final Set<int> _highlighted = {}; // ayahNumber set

  @override
  Widget build(BuildContext context) {
    final verseStyle = AppTheme.arabicVerseStyle(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = isDark ? AppTheme.ayahNumberGoldLight : AppTheme.ayahNumberGold;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: widget.ayahs.length,
        itemBuilder: (context, index) {
          final ayah = widget.ayahs[index];
          final isHighlighted = _highlighted.contains(ayah.ayahNumber);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isHighlighted) _highlighted.remove(ayah.ayahNumber);
                else _highlighted.add(ayah.ayahNumber);
              });
            },
            child: Container(
              color: isHighlighted ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: verseStyle,
                        children: _buildHighlightedSpans(context, ayah.textAr, verseStyle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AyahNumberBadge(number: ayah.ayahNumber, goldColor: goldColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<InlineSpan> _buildHighlightedSpans(BuildContext context, String text, TextStyle baseStyle) {
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
        } else if (idx == earliestStart && (longestPattern == null || pattern.length > longestPattern.length)) {
          longestPattern = pattern;
        }
      }

      if (earliestStart == null || longestPattern == null) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (earliestStart > start) {
        spans.add(TextSpan(text: text.substring(start, earliestStart), style: baseStyle));
      }
      spans.add(TextSpan(
        text: longestPattern,
        style: baseStyle.copyWith(color: redColor, fontWeight: FontWeight.w600),
      ));
      start = earliestStart + longestPattern.length;
    }
    return spans;
  }
}

class _AyahNumberBadge extends StatelessWidget {
  final int number;
  final Color goldColor;

  const _AyahNumberBadge({required this.number, required this.goldColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: goldColor, width: 1.2),
        color: goldColor.withOpacity(0.12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: goldColor,
        ),
      ),
    );
  }
}

class _SurahListScreen extends StatelessWidget {
  const _SurahListScreen();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة السور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder(
        future: repo.getSurahs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final surahs = snapshot.data!;
          return ListView.separated(
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                title: Text(
                  surah.nameAr,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.surahTitleStyle(context).copyWith(fontSize: 22),
                ),
                subtitle: Text('${surah.ayahCount} آية'),
                trailing: Text('${surah.id}'),
                onTap: () async {
                  final page = await repo.getFirstPageOfSurah(surah.id);
                  if (context.mounted) Navigator.of(context).pop(page);
                },
              );
            },
          );
        },
      ),
    );
  }
}
