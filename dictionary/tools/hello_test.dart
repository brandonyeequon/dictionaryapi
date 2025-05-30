import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test script to capture "hello" search response
void main() async {
  final tester = HelloTester();
  await tester.testHelloSearch();
}

class HelloTester {
  static const String baseUrl = 'https://jotoba.de/api/search/words';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Flutter-Dictionary-App/2.0-HelloTest',
    'Accept-Encoding': 'identity',
  };

  Future<void> testHelloSearch() async {
    print('Testing "hello" search...');
    
    try {
      final response = await _makeRequest('hello');
      
      print('Response received successfully!');
      print('Status code: ${response['status_code']}');
      
      // Save the full response
      final file = File('hello_search_response.json');
      final jsonString = const JsonEncoder.withIndent('  ').convert(response);
      await file.writeAsString(jsonString);
      
      print('Full response saved to hello_search_response.json');
      
      // Analyze the response
      final body = response['body'] as Map<String, dynamic>;
      
      if (body.containsKey('words') && body['words'] is List) {
        final words = body['words'] as List;
        print('\nFound ${words.length} words:');
        
        for (int i = 0; i < words.length; i++) {
          final word = words[i] as Map<String, dynamic>;
          
          // Extract reading info
          String kana = '';
          String kanji = '';
          if (word['reading'] is Map<String, dynamic>) {
            final reading = word['reading'] as Map<String, dynamic>;
            kana = reading['kana'] ?? '';
            kanji = reading['kanji'] ?? '';
          }
          
          // Extract first meaning
          String meaning = '';
          if (word['senses'] is List && (word['senses'] as List).isNotEmpty) {
            final firstSense = (word['senses'] as List).first as Map<String, dynamic>;
            if (firstSense['glosses'] is List && (firstSense['glosses'] as List).isNotEmpty) {
              meaning = (firstSense['glosses'] as List).first.toString();
            }
          }
          
          print('  ${i + 1}. $kanji ($kana) - $meaning');
          
          // Check specifically for こんにちは
          if (kana.contains('こんにちは') || kanji.contains('こんにちは')) {
            print('    *** FOUND こんにちは! ***');
          }
        }
      }
      
      if (body.containsKey('kanji') && body['kanji'] is List) {
        final kanji = body['kanji'] as List;
        print('\nFound ${kanji.length} kanji entries');
      }
      
    } catch (e) {
      print('Error: $e');
    }
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