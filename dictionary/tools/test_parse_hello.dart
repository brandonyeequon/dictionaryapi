import 'dart:convert';
import 'dart:io';
import '../lib/models/jotoba_word_entry.dart';
import '../lib/models/jotoba_response.dart';
import '../lib/models/jotoba_unified_response.dart';

/// Test parsing of hello response with our models
void main() async {
  final tester = ParseTester();
  await tester.testParsing();
}

class ParseTester {
  Future<void> testParsing() async {
    print('Testing parsing of hello response...');
    
    try {
      // Read the saved hello response
      final file = File('hello_search_response.json');
      final jsonString = await file.readAsString();
      final responseData = json.decode(jsonString) as Map<String, dynamic>;
      final body = responseData['body'] as Map<String, dynamic>;
      
      print('Loaded response data with ${body['words']?.length ?? 0} words');
      
      // Test 1: Parse individual word entries
      if (body['words'] is List) {
        final wordsArray = body['words'] as List;
        print('\n=== Testing individual word parsing ===');
        
        for (int i = 0; i < wordsArray.length && i < 3; i++) {
          final wordData = wordsArray[i] as Map<String, dynamic>;
          print('\nTesting word ${i + 1}:');
          print('Raw data: ${json.encode(wordData)}');
          
          try {
            final wordEntry = JotobaWordEntry.fromJson(wordData);
            print('✓ Parsed successfully!');
            print('  Primary word: ${wordEntry.primaryWord}');
            print('  Primary reading: ${wordEntry.primaryReading}');
            print('  Primary definition: ${wordEntry.primaryDefinition}');
            print('  All definitions: ${wordEntry.allDefinitions}');
            print('  Has furigana: ${wordEntry.hasPrimaryFurigana}');
            print('  Furigana: ${wordEntry.primaryFurigana}');
            
            // Check for こんにちは specifically
            if (wordEntry.primaryReading.contains('こんにちは') || 
                wordEntry.primaryWord.contains('こんにちは')) {
              print('  *** FOUND こんにちは in parsed entry! ***');
            }
          } catch (e) {
            print('✗ Failed to parse: $e');
          }
        }
      }
      
      // Test 2: Parse as JotobaResponse
      print('\n=== Testing JotobaResponse parsing ===');
      try {
        final response = JotobaResponse<JotobaWordEntry>.fromJson(
          body,
          (data) => JotobaWordEntry.fromJson(data),
        );
        print('✓ JotobaResponse parsed successfully!');
        print('  Result count: ${response.resultCount}');
        print('  Has results: ${response.hasResults}');
        
        if (response.data.isNotEmpty) {
          final firstEntry = response.data.first;
          print('  First entry: ${firstEntry.primaryWord} (${firstEntry.primaryReading}) - ${firstEntry.primaryDefinition}');
          
          if (firstEntry.primaryReading.contains('こんにちは') || 
              firstEntry.primaryWord.contains('こんにちは')) {
            print('  *** FOUND こんにちは in JotobaResponse! ***');
          }
        }
      } catch (e) {
        print('✗ Failed to parse JotobaResponse: $e');
      }
      
      // Test 3: Parse as JotobaUnifiedResponse
      print('\n=== Testing JotobaUnifiedResponse parsing ===');
      try {
        final unifiedResponse = JotobaUnifiedResponse.fromJson(body);
        print('✓ JotobaUnifiedResponse parsed successfully!');
        print('  Word count: ${unifiedResponse.wordCount}');
        print('  Kanji count: ${unifiedResponse.kanjiCount}');
        print('  Has results: ${unifiedResponse.hasResults}');
        
        if (unifiedResponse.words.isNotEmpty) {
          final firstEntry = unifiedResponse.words.first;
          print('  First word: ${firstEntry.primaryWord} (${firstEntry.primaryReading}) - ${firstEntry.primaryDefinition}');
          
          if (firstEntry.primaryReading.contains('こんにちは') || 
              firstEntry.primaryWord.contains('こんにちは')) {
            print('  *** FOUND こんにちは in JotobaUnifiedResponse! ***');
          }
        }
        
        // Check all words for こんにちは
        print('\n  All parsed words:');
        for (int i = 0; i < unifiedResponse.words.length; i++) {
          final word = unifiedResponse.words[i];
          print('    ${i + 1}. ${word.primaryWord} (${word.primaryReading}) - ${word.primaryDefinition}');
        }
        
      } catch (e) {
        print('✗ Failed to parse JotobaUnifiedResponse: $e');
      }
      
    } catch (e) {
      print('Error reading/parsing file: $e');
    }
  }
}