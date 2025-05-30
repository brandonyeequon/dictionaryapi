/// Represents a gloss (translation/definition) in a specific language
class JotobaGloss {
  final String text;
  final String language;
  final List<String> tags;

  JotobaGloss({
    required this.text,
    required this.language,
    required this.tags,
  });

  factory JotobaGloss.fromJson(Map<String, dynamic> json) {
    return JotobaGloss(
      text: json['text'] ?? json['gloss'] ?? '',
      language: json['language'] ?? 'English',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'tags': tags,
    };
  }

  /// Check if this is an English gloss
  bool get isEnglish => language.toLowerCase() == 'english';

  /// Check if gloss has tags
  bool get hasTags => tags.isNotEmpty;
}