// Smoke test for the TAJ app: the RTL shell renders and shows the brand mark.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/main.dart';

void main() {
  testWidgets('TAJ app renders the dashboard shell in RTL', (tester) async {
    await tester.pumpWidget(const TajApp(testSignedIn: true));
    await tester.pumpAndSettle();

    // Dashboard section heading is present.
    expect(find.text('لوحة التحكم'), findsWidgets);

    // The app is laid out right-to-left.
    expect(Directionality.of(tester.element(find.text('لوحة التحكم').first)),
        TextDirection.rtl);
  });
}
