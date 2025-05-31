// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary/main.dart';
import 'package:dictionary/models/enhanced_flashcard.dart';
import 'package:dictionary/widgets/flashcard_widget.dart';
import 'package:dictionary/widgets/ruby_text_widget.dart';


void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  // Helper to create an EnhancedFlashcard for testing
  EnhancedFlashcard createTestEnhancedFlashcard({
    String id = 'test-id',
    String word = '日本語',
    String reading = 'にほんご',
    String definition = 'Japanese language',
    String? furiganaReading,
    List<String> tags = const [],
    List<int> wordListIds = const [],
  }) {
    final now = DateTime.now();
    return EnhancedFlashcard(
      id: id,
      wordSlug: word, // simplified slug
      word: word,
      reading: reading,
      definition: definition,
      tags: tags,
      wordListIds: wordListIds,
      createdAt: now,
      lastReviewed: now,
      nextReview: now,
      furiganaReading: furiganaReading,
    );
  }

  testWidgets('FlashcardWidget displays RubyTextWidget when furiganaReading is present', (WidgetTester tester) async {
    final flashcardWithFurigana = createTestEnhancedFlashcard(
      word: '日本語',
      furiganaReading: '[日|に][本|ほん][語|ご]',
    );

    // Create a dummy flip animation
    final controller = AnimationController(vsync: tester, duration: Duration(milliseconds: 1));
    final flipAnimation = Tween<double>(begin: 0, end: 1).animate(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashcardWidget(
            flashcard: flashcardWithFurigana,
            showAnswer: false,
            flipAnimation: flipAnimation,
          ),
        ),
      ),
    );

    expect(find.byType(RubyTextWidget), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget); // RubyTextWidget will contain this
  });

  testWidgets('FlashcardWidget displays word directly (via RubyTextWidget fallback) when furiganaReading is null', (WidgetTester tester) async {
    final flashcardWithoutFurigana = createTestEnhancedFlashcard(
      word: 'にほんご', // Kana word
      furiganaReading: null,
    );

    final controller = AnimationController(vsync: tester, duration: Duration(milliseconds: 1));
    final flipAnimation = Tween<double>(begin: 0, end: 1).animate(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashcardWidget(
            flashcard: flashcardWithoutFurigana,
            showAnswer: false,
            flipAnimation: flipAnimation,
          ),
        ),
      ),
    );

    // RubyTextWidget is still used, but it internally renders plain text
    expect(find.byType(RubyTextWidget), findsOneWidget);
    expect(find.text('にほんご'), findsOneWidget);
  });
}
