import 'package:flutter/widgets.dart';

import 'demo_store.dart';

class DemoStoreProvider extends InheritedNotifier<DemoStore> {
  const DemoStoreProvider({
    super.key,
    required DemoStore store,
    required super.child,
  }) : super(notifier: store);

  static final DemoStore fallback = DemoStore();

  static DemoStore of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DemoStoreProvider>();
    return provider?.notifier ?? fallback;
  }
}
