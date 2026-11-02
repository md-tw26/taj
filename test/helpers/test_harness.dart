// Shared test harness: wraps a bare module screen with the `DemoStoreProvider`
// ancestor it expects.
//
// Before this helper existed, screens rendered without a `MaterialApp` +
// `DemoStoreProvider` of their own (most of the responsive test suites did
// this) silently fell back to `DemoStoreProvider.fallback` — a single hidden
// global store shared across every such test in the process. This helper
// makes that dependency explicit instead: every test now states which store
// (fixture-seeded by default) a screen sees.

import 'package:flutter/widgets.dart';

import 'package:taj/core/demo/demo_provider.dart';
import 'package:taj/core/demo/demo_store.dart';

import '../fixtures/sample_data.dart';

/// Wraps [child] with a [DemoStoreProvider]. Defaults to a fresh
/// fixture-seeded store (see `test/fixtures/sample_data.dart`); pass [store]
/// to test against a specific (e.g. empty) store instead.
Widget withStore(Widget child, {DemoStore? store}) =>
    DemoStoreProvider(store: store ?? buildSampleStore(), child: child);
