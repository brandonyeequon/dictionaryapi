import 'dart:convert';
import 'dart:io';

/// Minimal test to isolate the exact parsing issue
void main() async {
  print('Testing JotobaWordEntry parsing manually...');
  
  // Read the hello response  
  final file = File('hello_search_response.json');
  final jsonString = await file.readAsString();
  final responseData = json.decode(jsonString) as Map<String, dynamic>;
  final body = responseData['body'] as Map<String, dynamic>;
  
  if (body['words'] is List) {
    final wordsArray = body['words'] as List;
    final firstWordData = wordsArray[0] as Map<String, dynamic>;
    
    print('Raw first word data:');
    print(json.encode(firstWordData));
    
    // Manually trace through the parsing logic from JotobaWordEntry._parseReadings
    print('\n=== Manual parsing trace ===');
    
    // Check reading structure
    print('Reading field exists: ${firstWordData.containsKey('reading')}');
    print('Reading is Map: ${firstWordData['reading'] is Map<String, dynamic>}');
    
    if (firstWordData['reading'] is Map<String, dynamic>) {
      final readingData = firstWordData['reading'] as Map<String, dynamic>;
      print('Reading data: ${json.encode(readingData)}');
      
      final kanji = readingData['kanji'];
      final kana = readingData['kana'] ?? '';
      final furigana = readingData['furigana'];
      
      print('Extracted kanji: $kanji');
      print('Extracted kana: $kana');
      print('Extracted furigana: $furigana');
      
      // Simulate primaryWord getter logic
      final primaryWord = kanji ?? kana;
      final primaryReading = kana;
      
      print('\nSimulated getter results:');
      print('primaryWord would be: $primaryWord');
      print('primaryReading would be: $primaryReading');
      
      // Check for こんにちは
      if (primaryReading.contains('こんにちは') || primaryWord.contains('こんにちは')) {
        print('*** SUCCESS: こんにちは found in parsed data! ***');
      } else {
        print('*** ISSUE: こんにちは NOT found in parsed data ***');
      }
    }
    
    // Check senses/definitions
    print('\n=== Checking senses ===');
    if (firstWordData['senses'] is List) {
      final senses = firstWordData['senses'] as List;
      print('Number of senses: ${senses.length}');
      
      if (senses.isNotEmpty) {
        final firstSense = senses[0] as Map<String, dynamic>;
        print('First sense: ${json.encode(firstSense)}');
        
        if (firstSense['glosses'] is List) {
          final glosses = firstSense['glosses'] as List;
          print('Glosses: $glosses');
          
          if (glosses.isNotEmpty) {
            final firstGloss = glosses[0].toString();
            print('First definition: $firstGloss');
          }
        }
      }
    }
  }
}