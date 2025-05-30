import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Script to collect Jotoba API responses for analysis
/// Run with: dart api_response_collector.dart
void main() async {
  final collector = ApiResponseCollector();
  await collector.collectResponses();
}

class ApiResponseCollector {
  static const String baseUrl = 'https://jotoba.de/api/search/words';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Flutter-Dictionary-App/2.0-Analysis',
    'Accept-Encoding': 'identity',
  };

  // Common search terms to test
  final List<String> englishTerms = [
    'eat',
    'school',
    'friend',
    'simple',
  ];

  final List<String> japaneseTerms = [
    '家',          // house  
    '水',          // water
    '本',          // book
  ];

  final List<String> kanjiTerms = [
    '今',          // now
    '人',          // person
    '日',          // day
  ];

  Future<void> collectResponses() async {
    print('Starting API response collection...');
    
    // Create output directory
    final outputDir = Directory('api_responses');
    if (!await outputDir.exists()) {
      await outputDir.create();
    }

    // Collect English search responses
    await _collectTermResponses(englishTerms, 'english_searches.json', 'English');
    
    // Collect Japanese search responses  
    await _collectTermResponses(japaneseTerms, 'japanese_searches.json', 'Japanese');
    
    // Collect Kanji search responses
    await _collectTermResponses(kanjiTerms, 'kanji_searches.json', 'Kanji');

    print('API response collection completed!');
    print('Files saved in api_responses/ directory');
  }

  Future<void> _collectTermResponses(List<String> terms, String filename, String category) async {
    print('Collecting $category responses...');
    
    final responses = <Map<String, dynamic>>[];
    
    for (final term in terms) {
      print('  Fetching: $term');
      
      try {
        final response = await _makeRequest(term);
        
        responses.add({
          'search_term': term,
          'category': category,
          'timestamp': DateTime.now().toIso8601String(),
          'response': response,
        });
        
        // Add small delay to be respectful to the API
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        print('    Error fetching $term: $e');
        responses.add({
          'search_term': term,
          'category': category,
          'timestamp': DateTime.now().toIso8601String(),
          'error': e.toString(),
        });
      }
    }
    
    // Save to file
    final file = File('api_responses/$filename');
    final jsonString = const JsonEncoder.withIndent('  ').convert(responses);
    await file.writeAsString(jsonString);
    
    print('  Saved ${responses.length} responses to $filename');
  }

  Future<Map<String, dynamic>> _makeRequest(String query) async {
    final requestBody = {
      'query': query,
      'language': 'English',
      'no_english': false,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return {
        'status_code': response.statusCode,
        'headers': response.headers,
        'body': jsonData,
      };
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
}