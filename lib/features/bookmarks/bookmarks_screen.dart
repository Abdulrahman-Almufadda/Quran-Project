import 'package:flutter/material.dart';
import '../../core/widgets/platform_adaptive.dart';
import 'package:provider/provider.dart';

import '../../core/db/quran_repository.dart';
import '../../core/models/bookmark.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<Bookmark>> _futureBookmarks;

  @override
  void initState() {
    super.initState();
    final repo = context.read<QuranRepository>();
    _futureBookmarks = repo.getBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: platformAppBar(
        context: context,
        title: const Text('العلامات المرجعية'),
      ),
      body: FutureBuilder<List<Bookmark>>(
        future: _futureBookmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في تحميل العلامات'));
          }

          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return const Center(child: Text('لا توجد علامات مرجعية بعد'));
          }

          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              return ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text('سورة ${b.surahId}، آية ${b.ayahNumber}'),
              );
            },
          );
        },
      ),
    );
  }
}

