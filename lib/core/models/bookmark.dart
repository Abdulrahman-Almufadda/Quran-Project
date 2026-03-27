class Bookmark {
  final int id;
  final int surahId;
  final int ayahNumber;
  final int createdAt;
  final String? note;

  Bookmark({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.createdAt,
    this.note,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int,
        surahId: map['surah_id'] as int,
        ayahNumber: map['ayah_number'] as int,
        createdAt: map['created_at'] as int,
        note: map['note'] as String?,
      );
}

