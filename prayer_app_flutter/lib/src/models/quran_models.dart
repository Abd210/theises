class SurahMeta {
  final int number;
  final String nameAr;
  final String englishName;
  final String englishNameTranslation;
  final int ayahCount;
  final String revelationType;

  const SurahMeta({
    required this.number,
    required this.nameAr,
    required this.englishName,
    required this.englishNameTranslation,
    required this.ayahCount,
    required this.revelationType,
  });

  factory SurahMeta.fromApi(Map<String, dynamic> json) {
    return SurahMeta(
      number: json['number'] as int? ?? 0,
      nameAr: (json['name'] as String?) ?? '',
      englishName: (json['englishName'] as String?) ?? '',
      englishNameTranslation: (json['englishNameTranslation'] as String?) ?? '',
      ayahCount: json['numberOfAyahs'] as int? ?? 0,
      revelationType: (json['revelationType'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': nameAr,
        'englishName': englishName,
        'englishNameTranslation': englishNameTranslation,
        'numberOfAyahs': ayahCount,
        'revelationType': revelationType,
      };
}

class Ayah {
  final int numberInSurah;
  final String textAr;
  final String? textEn;

  const Ayah({
    required this.numberInSurah,
    required this.textAr,
    this.textEn,
  });

  Ayah copyWith({String? textEn}) {
    return Ayah(
      numberInSurah: numberInSurah,
      textAr: textAr,
      textEn: textEn ?? this.textEn,
    );
  }

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'textAr': textAr,
        'textEn': textEn,
      };
}

class JuzAyah {
  final int surahNumber;
  final int numberInSurah;
  final String textAr;
  final String? textEn;

  const JuzAyah({
    required this.surahNumber,
    required this.numberInSurah,
    required this.textAr,
    this.textEn,
  });

  JuzAyah copyWith({String? textEn}) {
    return JuzAyah(
      surahNumber: surahNumber,
      numberInSurah: numberInSurah,
      textAr: textAr,
      textEn: textEn ?? this.textEn,
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'numberInSurah': numberInSurah,
        'textAr': textAr,
        'textEn': textEn,
      };
}

class PageAyah {
  final int globalNumber;
  final int surahNumber;
  final String surahNameAr;
  final String surahEnglishName;
  final int numberInSurah;
  final String textAr;
  final String? textEn;
  final int juz;
  final int page;

  const PageAyah({
    required this.globalNumber,
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahEnglishName,
    required this.numberInSurah,
    required this.textAr,
    this.textEn,
    required this.juz,
    required this.page,
  });

  PageAyah copyWith({String? textEn}) {
    return PageAyah(
      globalNumber: globalNumber,
      surahNumber: surahNumber,
      surahNameAr: surahNameAr,
      surahEnglishName: surahEnglishName,
      numberInSurah: numberInSurah,
      textAr: textAr,
      textEn: textEn ?? this.textEn,
      juz: juz,
      page: page,
    );
  }

  factory PageAyah.fromApi(Map<String, dynamic> a, {bool english = false}) {
    final surah = a['surah'] as Map<String, dynamic>? ?? const {};
    return PageAyah(
      globalNumber: a['number'] as int? ?? 0,
      surahNumber: surah['number'] as int? ?? 0,
      surahNameAr: (surah['name'] as String?) ?? '',
      surahEnglishName: (surah['englishName'] as String?) ?? '',
      numberInSurah: a['numberInSurah'] as int? ?? 0,
      textAr: english ? '' : ((a['text'] as String?) ?? ''),
      textEn: english ? (a['text'] as String?) : null,
      juz: a['juz'] as int? ?? 1,
      page: a['page'] as int? ?? 1,
    );
  }
}

class QuranPointer {
  final int surahNumber;
  final int ayahNumber;
  final int? pageNumber;

  const QuranPointer({
    required this.surahNumber,
    required this.ayahNumber,
    this.pageNumber,
  });

  factory QuranPointer.fromJson(Map<String, dynamic> json) {
    return QuranPointer(
      surahNumber: json['surahNumber'] as int? ?? 1,
      ayahNumber: json['ayahNumber'] as int? ?? 1,
      pageNumber: json['pageNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        if (pageNumber != null) 'pageNumber': pageNumber,
      };

  String dedupeKey() => pageNumber != null
      ? 'page_$pageNumber'
      : '${surahNumber}_$ayahNumber';
}
