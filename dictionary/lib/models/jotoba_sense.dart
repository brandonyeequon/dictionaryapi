import 'jotoba_gloss.dart';

/// Represents a sense (meaning) of a Japanese word
class JotobaSense {
  final List<JotobaGloss> glosses;
  final List<String> partsOfSpeech;
  final Map<String, List<String>> detailedPartsOfSpeech;
  final List<String> tags;
  final List<String> info;
  final List<String> restrictions;
  final List<String> seeAlso;
  final List<String> antonyms;
  final List<String> source;
  final List<String> dialects;
  final List<String> fields;
  final List<String> misc;

  JotobaSense({
    required this.glosses,
    required this.partsOfSpeech,
    required this.detailedPartsOfSpeech,
    required this.tags,
    required this.info,
    required this.restrictions,
    required this.seeAlso,
    required this.antonyms,
    required this.source,
    required this.dialects,
    required this.fields,
    required this.misc,
  });

  factory JotobaSense.fromJson(Map<String, dynamic> json) {
    // Handle field property (can be string or list)
    List<String> fields = [];
    if (json['field'] is String) {
      fields.add(json['field']);
    } else if (json['field'] is List) {
      fields.addAll(List<String>.from(json['field']));
    }
    if (json['fields'] is List) {
      fields.addAll(List<String>.from(json['fields']));
    }
    
    // Handle dialect property
    List<String> dialects = [];
    if (json['dialect'] is String) {
      dialects.add(json['dialect']);
    } else if (json['dialect'] is List) {
      dialects.addAll(List<String>.from(json['dialect']));
    }
    if (json['dialects'] is List) {
      dialects.addAll(List<String>.from(json['dialects']));
    }
    
    // Handle xref property
    List<String> seeAlso = [];
    if (json['xref'] is String) {
      seeAlso.add(json['xref']);
    } else if (json['xref'] is List) {
      seeAlso.addAll(List<String>.from(json['xref']));
    }
    if (json['see_also'] is List) {
      seeAlso.addAll(List<String>.from(json['see_also']));
    }
    
    // Handle antonym property
    List<String> antonyms = [];
    if (json['antonym'] is String) {
      antonyms.add(json['antonym']);
    } else if (json['antonym'] is List) {
      antonyms.addAll(List<String>.from(json['antonym']));
    }
    if (json['antonyms'] is List) {
      antonyms.addAll(List<String>.from(json['antonyms']));
    }
    
    // Parse parts of speech with detailed information
    List<String> partsOfSpeech = [];
    Map<String, List<String>> detailedPartsOfSpeech = {};
    
    if (json['parts_of_speech'] is List) {
      partsOfSpeech = List<String>.from(json['parts_of_speech']);
    }
    
    // Parse pos field for detailed part of speech information
    if (json['pos'] is List) {
      for (final pos in json['pos']) {
        if (pos is String) {
          partsOfSpeech.add(pos);
          detailedPartsOfSpeech[pos] = detailedPartsOfSpeech[pos] ?? [];
        } else if (pos is Map<String, dynamic>) {
          for (final entry in pos.entries) {
            final posType = entry.key;
            final posValue = entry.value;
            
            // Add to parts of speech if not already there
            if (!partsOfSpeech.contains(posType)) {
              partsOfSpeech.add(posType);
            }
            
            // Initialize list if not exists
            detailedPartsOfSpeech[posType] = detailedPartsOfSpeech[posType] ?? [];
            
            // Handle nested structures like {"Verb": {"Godan": "Ru"}}
            if (posValue is Map<String, dynamic>) {
              // Extract nested information
              final nestedInfo = posValue.entries.map((e) => '${e.key}: ${e.value}').join(', ');
              detailedPartsOfSpeech[posType]!.add(nestedInfo);
            } else {
              final detail = posValue?.toString() ?? '';
              if (detail.isNotEmpty) {
                detailedPartsOfSpeech[posType]!.add(detail);
              }
            }
          }
        }
      }
    }
    
    // Parse info field - handle both 'info' list and 'information' string
    List<String> infoParsed = [];
    if (json['info'] != null) {
      infoParsed = _parseStringList(json['info']);
    } else if (json['information'] != null) {
      infoParsed = [json['information'].toString()];
    }
    
    return JotobaSense(
      glosses: (json['glosses'] as List<dynamic>? ?? [])
          .map((g) {
            if (g is String) {
              return JotobaGloss(text: g, language: 'English', tags: []);
            } else if (g is Map<String, dynamic>) {
              return JotobaGloss.fromJson(g);
            } else {
              return JotobaGloss(text: g.toString(), language: 'English', tags: []);
            }
          })
          .toList(),
      partsOfSpeech: partsOfSpeech,
      detailedPartsOfSpeech: detailedPartsOfSpeech,
      tags: _parseStringList(json['tags']),
      info: infoParsed,
      restrictions: _parseStringList(json['restrictions']),
      seeAlso: seeAlso,
      antonyms: antonyms,
      source: _parseStringList(json['source']),
      dialects: dialects,
      fields: fields,
      misc: _parseStringList(json['misc']),
    );
  }

  /// Helper method to parse string or list fields
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return List<String>.from(value);
    }
    if (value is String) {
      return [value];
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'glosses': glosses.map((g) => g.toJson()).toList(),
      'parts_of_speech': partsOfSpeech,
      'detailed_parts_of_speech': detailedPartsOfSpeech,
      'tags': tags,
      'info': info,
      'restrictions': restrictions,
      'see_also': seeAlso,
      'antonyms': antonyms,
      'source': source,
      'dialects': dialects,
      'fields': fields,
      'misc': misc,
    };
  }

  /// Get primary gloss text
  String get primaryGloss {
    return glosses.isNotEmpty ? glosses.first.text : '';
  }

  /// Get all gloss texts
  List<String> get allGlossTexts {
    return glosses.map((g) => g.text).toList();
  }

  /// Check if sense has part of speech information
  bool get hasPartsOfSpeech => partsOfSpeech.isNotEmpty;

  /// Get primary part of speech
  String? get primaryPartOfSpeech {
    return partsOfSpeech.isNotEmpty ? partsOfSpeech.first : null;
  }

  /// Check if sense has restrictions
  bool get hasRestrictions => restrictions.isNotEmpty;

  /// Check if sense has see also references
  bool get hasSeeAlso => seeAlso.isNotEmpty;

  /// Check if sense has antonyms
  bool get hasAntonyms => antonyms.isNotEmpty;
  
  /// Check if this sense contains an adjective
  bool get isAdjective => partsOfSpeech.contains('Adjective');
  
  /// Get adjective type (i-adjective, na-adjective, no-adjective)
  String? get adjectiveType {
    if (!isAdjective) return null;
    final adjectiveDetails = detailedPartsOfSpeech['Adjective'];
    if (adjectiveDetails == null || adjectiveDetails.isEmpty) return null;
    
    final adjectiveDetail = adjectiveDetails.first;
    switch (adjectiveDetail) {
      case 'Keiyoushi':
        return 'i-adjective';
      case 'Na':
        return 'na-adjective';
      case 'No':
        return 'no-adjective';
      default:
        return adjectiveDetail;
    }
  }
  
  /// Get readable adjective type display text
  String? get adjectiveTypeDisplay {
    final type = adjectiveType;
    if (type == null) return null;
    
    switch (type) {
      case 'i-adjective':
        return 'i-adj';
      case 'na-adjective':
        return 'na-adj';
      case 'no-adjective':
        return 'no-adj';
      default:
        return type;
    }
  }
  
  
  /// Get the primary POS category (Verb, Adjective, Noun, etc.)
  String? get primaryPosCategory {
    if (detailedPartsOfSpeech.containsKey('Verb')) return 'Verb';
    if (detailedPartsOfSpeech.containsKey('Adjective')) return 'Adjective';
    if (detailedPartsOfSpeech.containsKey('Noun')) return 'Noun';
    if (partsOfSpeech.isNotEmpty) return partsOfSpeech.first;
    return null;
  }
  
  /// Get simplified primary POS tag for main display (Verb, Noun, i-adj, na-adj)
  String? get primaryPosTag {
    if (detailedPartsOfSpeech.containsKey('Adjective')) {
      final adjectiveDetails = detailedPartsOfSpeech['Adjective'];
      if (adjectiveDetails != null && adjectiveDetails.isNotEmpty) {
        final adjectiveType = adjectiveDetails.first;
        switch (adjectiveType) {
          case 'Keiyoushi':
            return 'i-adj';
          case 'Na':
            return 'na-adj';
          case 'No':
            return 'no-adj';
          default:
            return 'Adjective';
        }
      }
    }
    if (detailedPartsOfSpeech.containsKey('Verb')) return 'Verb';
    if (detailedPartsOfSpeech.containsKey('Noun')) return 'Noun';
    
    // Fallback to first POS if available
    if (partsOfSpeech.isNotEmpty) {
      final pos = partsOfSpeech.first;
      if (pos == 'Suffix' || pos == 'Expr') return pos;
      return pos;
    }
    return null;
  }
  
  /// Get comprehensive POS tags including main type + all additional details
  List<String> get comprehensivePosDisplay {
    final List<String> tags = [];
    
    // Add primary POS tag first
    final primary = primaryPosTag;
    if (primary != null) {
      tags.add(primary);
    }
    
    // Add all verb details
    if (detailedPartsOfSpeech.containsKey('Verb')) {
      final verbDetails = detailedPartsOfSpeech['Verb']!;
      for (final detail in verbDetails) {
        if (detail == 'Ichidan') {
          tags.add('Ichidan');
        } else if (detail == 'Transitive') {
          tags.add('Transitive');
        } else if (detail == 'Intransitive') {
          tags.add('Intransitive');
        } else if (detail.contains('Godan:')) {
          final godanType = detail.split(': ').last;
          tags.add('Godan ($godanType)');
        } else if (detail.contains('Irregular:')) {
          tags.add('Irregular');
        }
      }
    }
    
    // Add noun details
    if (detailedPartsOfSpeech.containsKey('Noun')) {
      final nounDetails = detailedPartsOfSpeech['Noun']!;
      for (final detail in nounDetails) {
        if (detail == 'Suffix') {
          tags.add('Suffix');
        }
      }
    }
    
    // Add other POS types that aren't primary
    for (final pos in partsOfSpeech) {
      if (pos == 'Suffix' && !tags.contains('Suffix')) {
        tags.add('Suffix');
      } else if (pos == 'Expr' && !tags.contains('Expr')) {
        tags.add('Expr');
      }
    }
    
    return tags.toSet().toList(); // Remove duplicates
  }
}