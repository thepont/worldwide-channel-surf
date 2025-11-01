import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worldwide_channel_surf/main.dart';

void main() {
  testWidgets('App should start with HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Should show the home screen
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Should be wrapped in ProviderScope
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('App should have correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // MaterialApp should be present
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, equals('Worldwide Channel Surf'));
  });
}

