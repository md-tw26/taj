import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taj/main.dart';

void main() {
  testWidgets('probe admin 600', (tester) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
    };
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TajApp(testSignedIn: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    FlutterError.onError = prev;
    for (final e in errors.take(3)) {
      // Print just the widget/creator lines to keep it short.
      for (final line in const LineSplitter().convert(e)) {
        if (line.contains('.dart:') ||
            line.contains('overflowed') ||
            line.contains('error-causing') ||
            line.contains('Column') ||
            line.contains('Row')) {
          debugPrint('PROBE> $line');
        }
      }
    }
  });
}
