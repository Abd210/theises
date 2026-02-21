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

class QuranPointer {
  final int surahNumber;
  final int ayahNumber;

  const QuranPointer({required this.surahNumber, required this.ayahNumber});

  factory QuranPointer.fromJson(Map<String, dynamic> json) {
    return QuranPointer(
      surahNumber: json['surahNumber'] as int? ?? 1,
      ayahNumber: json['ayahNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
      };

  String dedupeKey() => '${surahNumber}_$ayahNumber';
}
