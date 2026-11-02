import 'package:flutter/widgets.dart';

import 'demo_store.dart';

class DemoStoreProvider extends InheritedNotifier<DemoStore> {
  const DemoStoreProvider({
    super.key,
    required DemoStore store,
    required super.child,
  }) : super(notifier: store);

  static DemoStore of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DemoStoreProvider>();
    assert(
      provider != null,
      'No DemoStoreProvider found. Wrap the app (or the widget under test — '
      'see test/helpers/test_harness.dart) in a DemoStoreProvider.',
    );
    return provider!.notifier!;
  }
}
