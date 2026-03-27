import 'package:flutter/services.dart';

/// Attempt to load a page SVG from assets using several common filename patterns.
/// Returns the SVG string if found, or null if not.
Future<String?> loadSvgForPage(int pageNumber) async {
  final candidates = <String>[];
  // pattern: zero-padded three-digit (001.svg) - matches the provided hafs files
  final padded = pageNumber.toString().padLeft(3, '0');

  // Prefer the cleaned mushaf pages produced by the stripping script first
  // so we avoid loading editor metadata embedded in the originals.
  candidates.add('mushaf-pages-cleaned/${padded}___Hafs39__DM.svg');
  candidates.add('mushaf-pages-cleaned/${pageNumber}___Hafs39__DM.svg');
  candidates.add('mushaf-pages-cleaned/$padded.svg');
  candidates.add('mushaf-pages-cleaned/$pageNumber.svg');
  candidates.add('mushaf-pages-cleaned/page-$pageNumber.svg');

  // Then try the original mushaf folder (in case you didn't run the cleaner).
  // We no longer consider the original (uncleaned) mushaf folder. The
  // cleaning script produces `mushaf-pages-cleaned/` which the app now
  // prefers exclusively. If you need other fallbacks, add them here.

  for (final path in candidates) {
    try {
      final svg = await rootBundle.loadString(path);
      if (svg.trim().isNotEmpty) return svg;
    } catch (_) {
      // try next
    }
  }
  return null;
}
