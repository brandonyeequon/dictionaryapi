import 'package:flutter/foundation.dart';

/// Generic response wrapper for Jotoba API responses
class JotobaResponse<T> {
  final List<T> data;
  final int? total;
  final String? nextPage;
  final Map<String, dynamic>? metadata;

  JotobaResponse({
    required this.data,
    this.total,
    this.nextPage,
    this.metadata,
  });

  factory JotobaResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Based on official Jotoba API docs: response has 'words' and 'kanji' keys
    List<dynamic> resultsList = [];
    
    // For word search, use the 'words' array if it exists
    if (json.containsKey('words') && json['words'] is List) {
      resultsList = json['words'];
    } 
    // For kanji search, use the 'kanji' array
    else if (json.containsKey('kanji') && json['kanji'] is List) {
      resultsList = json['kanji'];
    }
    // Fallback for other search types
    else {
      final possibleKeys = ['sentences', 'names', 'results', 'data'];
      for (final key in possibleKeys) {
        if (json.containsKey(key) && json[key] is List) {
          resultsList = json[key];
          break;
        }
      }
    }

    // Parse results with error handling
    final parsedResults = <T>[];
    for (final item in resultsList) {
      try {
        if (item is Map<String, dynamic>) {
          parsedResults.add(fromJsonT(item));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JotobaResponse] Failed to parse item: $e');
        }
        // Skip items that can't be parsed
        continue;
      }
    }
    
    return JotobaResponse(
      data: parsedResults,
      total: json['total'],
      nextPage: json['next_page'],
      metadata: json,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': data.map((item) => toJsonT(item)).toList(),
      if (total != null) 'total': total,
      if (nextPage != null) 'next_page': nextPage,
      if (metadata != null) 'metadata': metadata,
    };
  }

  bool get hasResults => data.isNotEmpty;
  int get resultCount => data.length;
  bool get hasMore => nextPage != null;
}