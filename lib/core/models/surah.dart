class Surah {
  final int id;
  final String nameAr;
  final String? nameEn;
  final int ayahCount;

  Surah({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.ayahCount,
  });

  factory Surah.fromMap(Map<String, dynamic> map) => Surah(
        id: map['id'] as int,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String?,
        ayahCount: map['ayah_count'] as int,
      );
}

