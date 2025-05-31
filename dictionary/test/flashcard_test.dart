import 'package:flutter_test/flutter_test.dart';
import 'package:dictionary/models/flashcard.dart';
import 'package:dictionary/models/jotoba_word_entry.dart';
import 'package:dictionary/models/jotoba_reading.dart';

void main() {
  group('Flashcard Model', () {
    // Helper to create a JotobaWordEntry
    JotobaWordEntry createTestJotobaEntry({
      String slug = '食べる',
      String primaryWord = '食べる',
      String primaryReading = 'たべる',
      String primaryDefinition = 'to eat',
      List<String> jlpt = const ['N5'],
      List<String> tags = const ['common'],
      String? primaryFurigana,
    }) {
      return JotobaWordEntry(
        slug: slug,
        reading: [
          JotobaReading(kanji: primaryWord, kana: primaryReading, furigana: primaryFurigana, tags: [], info: [])
        ],
        senses: [], // Simplified for this test, add senses if needed for definition
        audio: [],
        common: true,
        tags: tags,
        jlpt: jlpt,
        pitchAccent: [],
        pitchParts: [],
      );
    }

    final mockJotobaEntryWithFurigana = createTestJotobaEntry(
      primaryFurigana: '[食|た]べる',
    );

    final mockJotobaEntryWithoutFurigana = createTestJotobaEntry(
      primaryWord: 'たべる', // Kana only word
      primaryFurigana: null,
    );

    test('Flashcard.fromWordEntry creates correctly with furigana', () {
      final flashcard = Flashcard.fromWordEntry('id1', mockJotobaEntryWithFurigana);
      expect(flashcard.word, '食べる');
      expect(flashcard.reading, 'たべる');
      expect(flashcard.furiganaReading, '[食|た]べる');
      // expect(flashcard.definition, 'to eat'); // Needs senses in mock
      expect(flashcard.tags, containsAll(['N5', 'common']));
    });

    test('Flashcard.fromWordEntry creates correctly without furigana', () {
      final flashcard = Flashcard.fromWordEntry('id2', mockJotobaEntryWithoutFurigana);
      expect(flashcard.word, 'たべる');
      expect(flashcard.reading, 'たべる');
      expect(flashcard.furiganaReading, isNull);
    });

    test('Flashcard toJson/fromJson serialization works with furiganaReading', () {
      final now = DateTime.now();
      final original = Flashcard(
        id: 'id3',
        wordSlug: 'slug',
        word: '言葉',
        reading: 'ことば',
        definition: 'word',
        tags: ['tag1'],
        createdAt: now,
        lastReviewed: now,
        nextReview: now.add(Duration(days: 1)),
        furiganaReading: '[言|こと][葉|ば]',
      );
      final json = original.toJson();
      expect(json['furigana_reading'], '[言|こと][葉|ば]');

      final deserialized = Flashcard.fromJson(json);
      expect(deserialized.furiganaReading, '[言|こと][葉|ば]');
      expect(deserialized.word, '言葉');
    });

     test('Flashcard toJson/fromJson serialization works with null furiganaReading', () {
      final now = DateTime.now();
      final original = Flashcard(
        id: 'id4',
        wordSlug: 'slug2',
        word: 'かな',
        reading: 'かな',
        definition: 'kana',
        tags: ['tag2'],
        createdAt: now,
        lastReviewed: now,
        nextReview: now.add(Duration(days: 1)),
        furiganaReading: null,
      );
      final json = original.toJson();
      expect(json['furigana_reading'], isNull);

      final deserialized = Flashcard.fromJson(json);
      expect(deserialized.furiganaReading, isNull);
      expect(deserialized.word, 'かな');
    });
  });
}
