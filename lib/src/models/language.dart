/// Language metadata for multi-language support.
class Language {
  final String languageCode;
  final String language;

  const Language({
    required this.languageCode,
    required this.language,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      languageCode: json['language_code'] as String? ?? 'en',
      language: json['language'] as String? ?? 'English',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language_code': languageCode,
      'language': language,
    };
  }
}
