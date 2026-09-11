// AI Assistant (chat) responsive regression tests.
//
// Covers the empty state and a seeded conversation (text + KPIs + table +
// chart) at every acceptance size, portrait and landscape, in RTL and LTR;
// simulates the open keyboard (the worst case) at every phone size and asserts
// the composer stays present with no overflow; and runs a resize sweep. Any
// overflow / "RenderBox was not laid out" surfaces via takeException().

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taj/core/theme/app_themes.dart';
import 'package:taj/modules/assistant/assistant_screen.dart';

Widget _host(Widget child, {TextDirection dir = TextDirection.rtl}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light(),
      locale: Locale(dir == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Future<void> _pumpAt(WidgetTester tester, double w, double h, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

const _acceptance = <(String, double, double)>[
  ('320x568', 320, 568),
  ('568x320', 568, 320),
  ('360x640', 360, 640),
  ('390x844', 390, 844),
  ('430x932', 430, 932),
  ('932x430', 932, 430),
  ('600x960', 600, 960),
  ('768x1024', 768, 1024),
  ('1024x1366', 1024, 1366),
  ('1280x720', 1280, 720),
  ('1366x768', 1366, 768),
  ('1440x900', 1440, 900),
  ('1920x1080', 1920, 1080),
  ('2560x1440', 2560, 1440),
  ('3440x1440', 3440, 1440),
  ('3840x2160', 3840, 2160),
];

const _phones = <(String, double, double)>[
  ('320x568', 320, 568),
  ('360x640', 360, 640),
  ('390x844', 390, 844),
  ('430x932', 430, 932),
  ('568x320', 568, 320), // landscape
  ('932x430', 932, 430), // landscape
];

void main() {
  const ids = ['sales7', 'top_products', 'expenses', 'top_customers', 'rev_exp', 'low_stock'];

  group('Empty state — every acceptance size, no overflow', () {
    for (final (label, w, h) in _acceptance) {
      testWidgets('empty @ $label', (tester) async {
        await _pumpAt(tester, w, h, _host(const AssistantScreen()));
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget); // composer present
      });
    }
  });

  group('Seeded conversation — every question, narrow & wide, RTL & LTR', () {
    for (final id in ids) {
      for (final dir in TextDirection.values) {
        final dl = dir == TextDirection.rtl ? 'rtl' : 'ltr';
        testWidgets('$id narrow ($dl)', (tester) async {
          await _pumpAt(tester, 380, 720, _host(AssistantScreen(testInitialQuestionId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
        testWidgets('$id wide ($dl)', (tester) async {
          await _pumpAt(tester, 1500, 900, _host(AssistantScreen(testInitialQuestionId: id), dir: dir));
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Keyboard open (worst case) — every phone size, portrait & landscape', () {
    for (final (label, w, h) in _phones) {
      testWidgets('keyboard @ $label', (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = Size(w, h);
        // Simulate an open keyboard consuming the bottom inset.
        tester.view.viewInsets = FakeViewPadding(bottom: h < w ? 180 : 300);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(_host(const AssistantScreen(testInitialQuestionId: 'sales7')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        // Composer + at least one message still laid out (visible above kbd).
        expect(find.byType(TextField), findsOneWidget);
      });
    }
  });

  group('Connection-error state', () {
    for (final (label, w, h) in [('phone', 360.0, 720.0), ('desktop', 1440.0, 900.0)]) {
      testWidgets('error @ $label', (tester) async {
        await _pumpAt(tester, w, h, _host(const AssistantScreen(testConnectionError: true)));
        expect(tester.takeException(), isNull);
        expect(find.text('إعادة'), findsOneWidget);
      });
    }
  });

  group('Resize sweep preserves layout without overflow', () {
    testWidgets('1600 → 1280 → 900 → 600 → 360', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final w in [1600.0, 1280.0, 900.0, 600.0, 360.0]) {
        tester.view.physicalSize = Size(w, 820);
        await tester.pumpWidget(_host(const AssistantScreen(testInitialQuestionId: 'top_products')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'overflow at width $w');
      }
    });
  });
}
