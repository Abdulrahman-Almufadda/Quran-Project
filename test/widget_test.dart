import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aya_quran/app.dart';

void main() {
  testWidgets('App launches and provides MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const QuranApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
