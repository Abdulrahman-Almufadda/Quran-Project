class Ayah {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String textAr;
  final int page;

  Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.textAr,
    this.page = 1,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) => Ayah(
        id: map['id'] as int,
        surahId: map['surah_id'] as int,
        ayahNumber: map['ayah_number'] as int,
        textAr: map['text_ar'] as String,
        page: (map['page'] as int?) ?? 1,
      );
}

