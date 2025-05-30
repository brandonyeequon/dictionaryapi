import 'jotoba_reading.dart';
import 'jotoba_sense.dart';
import 'jotoba_pitch_accent.dart';
import 'jotoba_pitch_part.dart';
import 'jotoba_gloss.dart';

/// Represents a word entry from Jotoba API
class JotobaWordEntry {
  final int? id;
  final String? slug;
  final List<JotobaReading> reading;
  final List<JotobaSense> senses;
  final List<String> audio;
  final bool common;
  final List<String> tags;
  final List<String> jlpt;
  final List<JotobaPitchAccent> pitchAccent;
  final List<JotobaPitchPart> pitchParts;
  final int? frequency;
  final Map<String, dynamic>? collocations;
  final List<String>? alternativeSpellings;

  JotobaWordEntry({
    this.id,
    this.slug,
    required this.reading,
    required this.senses,
    required this.audio,
    required this.common,
    required this.tags,
    required this.jlpt,
    required this.pitchAccent,
    required this.pitchParts,
    this.frequency,
    this.collocations,
    this.alternativeSpellings,
  });

  factory JotobaWordEntry.fromJson(Map<String, dynamic> json) {
    return JotobaWordEntry(
      id: json['id'],
      slug: json['slug'],
      // Handle both 'reading' array and direct kanji/kana fields
      reading: _parseReadings(json),
      senses: _parseSenses(json),
      audio: _parseAudio(json),
      common: _parseBool(json['common']),
      tags: _parseStringList(json['tags']),
      jlpt: _parseStringList(json['jlpt']),
      pitchAccent: _parsePitchAccent(json),
      pitchParts: _parsePitchParts(json),
      frequency: json['frequency'],
      collocations: json['collocations'],
      alternativeSpellings: _parseStringListNullable(json['alternative_spellings']),
    );
  }

  static List<JotobaReading> _parseReadings(Map<String, dynamic> json) {
    // Handle single reading object (actual Jotoba format)
    if (json['reading'] is Map<String, dynamic>) {
      final readingData = json['reading'] as Map<String, dynamic>;
      return [
        JotobaReading(
          kanji: readingData['kanji'],
          kana: readingData['kana'] ?? '',
          tags: [],
          info: [],
          furigana: readingData['furigana'],
        )
      ];
    }
    
    // Handle reading array (fallback)
    if (json['reading'] is List) {
      return (json['reading'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((r) => JotobaReading.fromJson(r))
          .toList();
    }
    
    // Handle direct kanji/kana fields
    if (json['kanji'] != null || json['kana'] != null) {
      return [
        JotobaReading(
          kanji: json['kanji'],
          kana: json['kana'] ?? '',
          tags: [],
          info: [],
          furigana: json['furigana'],
        )
      ];
    }
    
    // Handle kanji entry structure (from kanji search results)
    if (json['literal'] != null) {
      final kunyomi = json['kunyomi'] is List ? json['kunyomi'] as List : [];
      final onyomi = json['onyomi'] is List ? json['onyomi'] as List : [];
      
      String kanaReading = json['literal'];
      if (kunyomi.isNotEmpty) {
        kanaReading = kunyomi.first.toString();
      } else if (onyomi.isNotEmpty) {
        kanaReading = onyomi.first.toString();
      }
      
      return [
        JotobaReading(
          kanji: json['literal'],
          kana: kanaReading,
          tags: [],
          info: [],
          furigana: null,
        )
      ];
    }
    
    return [];
  }

  static List<JotobaSense> _parseSenses(Map<String, dynamic> json) {
    if (json['senses'] is List) {
      final sensesList = json['senses'] as List<dynamic>;
      return sensesList.whereType<Map<String, dynamic>>().map((senseData) {
        // Create glosses from the glosses array
        final glosses = <JotobaGloss>[];
        if (senseData['glosses'] is List) {
          for (final gloss in senseData['glosses']) {
            if (gloss is String) {
              glosses.add(JotobaGloss(
                text: gloss,
                language: senseData['language'] ?? 'English',
                tags: [],
              ));
            }
          }
        }
        
        // Create properly structured sense data for JotobaSense.fromJson
        Map<String, dynamic> senseWithPos = Map<String, dynamic>.from(senseData);
        
        // Ensure glosses are properly formatted for JotobaSense.fromJson
        if (glosses.isNotEmpty) {
          senseWithPos['glosses'] = glosses.map((g) => g.toJson()).toList();
        }
        
        // Extract misc info
        final misc = <String>[];
        if (senseData['misc'] is String) {
          misc.add(senseData['misc']);
        }
        if (misc.isNotEmpty) {
          senseWithPos['misc'] = misc;
        }
        
        // Extract information
        final info = <String>[];
        if (senseData['information'] is String) {
          info.add(senseData['information']);
        }
        if (info.isNotEmpty) {
          senseWithPos['info'] = info;
        }
        
        return JotobaSense.fromJson(senseWithPos);
      }).toList();
    }
    
    // Fallback: create sense from meanings if available (for kanji entries)
    if (json['meanings'] is List) {
      final meanings = json['meanings'] as List;
      final glosses = meanings
          .map((m) => JotobaGloss(text: m.toString(), language: 'English', tags: []))
          .toList();
      
      // For kanji entries, add additional info
      final info = <String>[];
      if (json['grade'] != null) {
        info.add('Grade: ${json['grade']}');
      }
      if (json['jlpt'] != null) {
        info.add('JLPT: N${json['jlpt']}');
      }
      if (json['frequency'] != null) {
        info.add('Frequency: ${json['frequency']}');
      }
      if (json['stroke_count'] != null) {
        info.add('Strokes: ${json['stroke_count']}');
      }
      
      return [
        JotobaSense(
          glosses: glosses,
          partsOfSpeech: json['literal'] != null ? ['kanji'] : [],
          detailedPartsOfSpeech: {},
          tags: [],
          info: info,
          restrictions: [],
          seeAlso: [],
          antonyms: [],
          source: [],
          dialects: [],
          fields: [],
          misc: [],
        )
      ];
    }
    
    return [];
  }

  static List<String> _parseAudio(Map<String, dynamic> json) {
    if (json['audio'] is List) {
      return List<String>.from(json['audio']);
    }
    if (json['audio'] is String) {
      return [json['audio']];
    }
    return [];
  }

  static List<JotobaPitchAccent> _parsePitchAccent(Map<String, dynamic> json) {
    // Handle both 'pitch_accent' and 'pitch' fields
    List<dynamic>? pitchData;
    if (json['pitch_accent'] is List) {
      pitchData = json['pitch_accent'] as List<dynamic>;
    } else if (json['pitch'] is List) {
      pitchData = json['pitch'] as List<dynamic>;
    }
    
    if (pitchData != null) {
      return pitchData
          .whereType<Map<String, dynamic>>()
          .map((p) => JotobaPitchAccent.fromJson(p))
          .toList();
    }
    return [];
  }

  static List<JotobaPitchPart> _parsePitchParts(Map<String, dynamic> json) {
    // Handle the 'pitch' array from Jotoba API
    if (json['pitch'] is List) {
      final pitchData = json['pitch'] as List<dynamic>;
      return pitchData
          .whereType<Map<String, dynamic>>()
          .map((p) => JotobaPitchPart.fromJson(p))
          .toList();
    }
    return [];
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return [value];
    }
    return [];
  }

  static List<String>? _parseStringListNullable(dynamic value) {
    if (value == null) return null;
    return _parseStringList(value);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      'reading': reading.map((r) => r.toJson()).toList(),
      'senses': senses.map((s) => s.toJson()).toList(),
      'audio': audio,
      'common': common,
      'tags': tags,
      'jlpt': jlpt,
      'pitch_accent': pitchAccent.map((p) => p.toJson()).toList(),
      'pitch': pitchParts.map((p) => p.toJson()).toList(),
      if (frequency != null) 'frequency': frequency,
      if (collocations != null) 'collocations': collocations,
      if (alternativeSpellings != null) 'alternative_spellings': alternativeSpellings,
    };
  }

  /// Get the primary kanji/word form
  String get primaryWord {
    if (reading.isNotEmpty) {
      final primaryReading = reading.first;
      return primaryReading.kanji ?? primaryReading.kana;
    }
    return slug ?? '';
  }

  /// Get the primary kana reading
  String get primaryReading {
    if (reading.isNotEmpty) {
      return reading.first.kana;
    }
    return '';
  }

  /// Get the primary English definition
  String get primaryDefinition {
    if (senses.isNotEmpty && senses.first.glosses.isNotEmpty) {
      return senses.first.glosses.first.text;
    }
    return '';
  }

  /// Get all definitions across all senses
  List<String> get allDefinitions {
    return senses
        .expand((sense) => sense.glosses)
        .map((gloss) => gloss.text)
        .toList();
  }

  /// Get consolidated definitions grouped by sense
  /// Returns definitions in format: "1. hello, good day, good afternoon 2. well, thanks"
  String get consolidatedDefinitions {
    if (senses.isEmpty) return '';
    
    final consolidatedSenses = <String>[];
    
    for (int i = 0; i < senses.length; i++) {
      final sense = senses[i];
      if (sense.glosses.isNotEmpty) {
        final glossTexts = sense.glosses.map((gloss) => gloss.text).join(', ');
        consolidatedSenses.add('${i + 1}. $glossTexts');
      }
    }
    
    return consolidatedSenses.join(' ');
  }

  /// Check if word has pitch accent data
  bool get hasPitchAccent => pitchAccent.isNotEmpty;

  /// Check if word has audio
  bool get hasAudio => audio.isNotEmpty;

  /// Get primary audio URL
  String? get primaryAudioUrl => audio.isNotEmpty ? audio.first : null;

  /// Check if word is JLPT level
  bool get hasJlptLevel => jlpt.isNotEmpty;

  /// Get JLPT level (N1-N5)
  String? get jlptLevel => jlpt.isNotEmpty ? jlpt.first : null;

  /// Get frequency rank if available
  int? get frequencyRank => frequency;

  /// Check if word is marked as common
  bool get isCommon => common;
  
  /// Get the primary POS tag for this word (Verb, Noun, i-adj, na-adj)
  String? get primaryPosTag {
    if (senses.isNotEmpty) {
      return senses.first.primaryPosTag;
    }
    return null;
  }

  /// Check if the primary reading has furigana
  bool get hasPrimaryFurigana {
    if (reading.isNotEmpty) {
      return reading.first.hasFurigana;
    }
    return false;
  }

  /// Get the primary furigana reading
  String? get primaryFurigana {
    if (reading.isNotEmpty) {
      return reading.first.furigana;
    }
    return null;
  }
}