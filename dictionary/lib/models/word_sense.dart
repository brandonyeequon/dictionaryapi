class WordSense {
  final List<String> englishDefinitions;
  final List<String> partsOfSpeech;
  final List<Map<String, String>> links;
  final List<String> tags;
  final List<String> restrictions;
  final List<String> seeAlso;
  final List<String> antonyms;
  final List<Map<String, dynamic>> source;
  final List<String> info;
  final List<String>? sentences;

  WordSense({
    required this.englishDefinitions,
    required this.partsOfSpeech,
    required this.links,
    required this.tags,
    required this.restrictions,
    required this.seeAlso,
    required this.antonyms,
    required this.source,
    required this.info,
    this.sentences,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) {
    return WordSense(
      englishDefinitions: List<String>.from(json['english_definitions'] ?? []),
      partsOfSpeech: List<String>.from(json['parts_of_speech'] ?? []),
      links: List<Map<String, String>>.from(
        (json['links'] ?? []).map((link) => Map<String, String>.from(link)),
      ),
      tags: List<String>.from(json['tags'] ?? []),
      restrictions: List<String>.from(json['restrictions'] ?? []),
      seeAlso: List<String>.from(json['see_also'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
      source: _parseSource(json['source'] ?? []),
      info: List<String>.from(json['info'] ?? []),
      sentences: json['sentences'] != null 
          ? List<String>.from(json['sentences']) 
          : null,
    );
  }

  static List<Map<String, dynamic>> _parseSource(dynamic sourceData) {
    if (sourceData is List) {
      return sourceData.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is String) {
          // Handle legacy string format by converting to map
          return {'text': item};
        } else {
          return {'text': item.toString()};
        }
      }).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'english_definitions': englishDefinitions,
      'parts_of_speech': partsOfSpeech,
      'links': links,
      'tags': tags,
      'restrictions': restrictions,
      'see_also': seeAlso,
      'antonyms': antonyms,
      'source': source,
      'info': info,
      'sentences': sentences,
    };
  }
}