import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanderless/main.dart';

void main() {
  testWidgets('WanderLess app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WanderlessApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
