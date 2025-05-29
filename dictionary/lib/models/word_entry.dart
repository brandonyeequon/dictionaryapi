import 'japanese_reading.dart';
import 'word_sense.dart';
import 'attribution.dart';

class WordEntry {
  final String slug;
  final bool isCommon;
  final List<String> tags;
  final List<String> jlpt;
  final List<JapaneseReading> japanese;
  final List<WordSense> senses;
  final Attribution attribution;

  WordEntry({
    required this.slug,
    required this.isCommon,
    required this.tags,
    required this.jlpt,
    required this.japanese,
    required this.senses,
    required this.attribution,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      slug: json['slug'] ?? '',
      isCommon: json['is_common'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      jlpt: List<String>.from(json['jlpt'] ?? []),
      japanese: (json['japanese'] as List<dynamic>? ?? [])
          .map((j) => JapaneseReading.fromJson(j))
          .toList(),
      senses: (json['senses'] as List<dynamic>? ?? [])
          .map((s) => WordSense.fromJson(s))
          .toList(),
      attribution: Attribution.fromJson(json['attribution'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'is_common': isCommon,
      'tags': tags,
      'jlpt': jlpt,
      'japanese': japanese.map((j) => j.toJson()).toList(),
      'senses': senses.map((s) => s.toJson()).toList(),
      'attribution': attribution.toJson(),
    };
  }

  String get mainWord => japanese.isNotEmpty 
      ? japanese.first.word ?? japanese.first.reading 
      : slug;

  String get mainReading => japanese.isNotEmpty 
      ? japanese.first.reading 
      : '';

  String get primaryDefinition => senses.isNotEmpty && 
      senses.first.englishDefinitions.isNotEmpty
      ? senses.first.englishDefinitions.first 
      : '';

  List<String> get allDefinitions => senses
      .expand((sense) => sense.englishDefinitions)
      .toList();
}