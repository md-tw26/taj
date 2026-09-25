import 'package:flutter/widgets.dart';

import 'license_service.dart';

/// Exposes the live [LicenseGateState] to descendants (Settings reads it to
/// show status/plan/expiry and to deactivate).
///
/// Owned by `_TajAppState` and placed under `DatabaseProvider`, so everything
/// below it can both read the state and reach the database. Changing
/// [state] flips the app gate without a restart.
class LicenseScope extends InheritedWidget {
  const LicenseScope({
    super.key,
    required this.state,
    required this.refresh,
    required super.child,
  });

  /// The gate state. Listen with a [ValueListenableBuilder].
  final ValueNotifier<LicenseGateState> state;

  /// Re-reads and re-validates the stored license (used after activation and
  /// after deactivation).
  final Future<void> Function() refresh;

  static LicenseScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LicenseScope>();
    assert(scope != null, 'No LicenseScope found in context');
    return scope!;
  }

  /// `null` when the subtree is mounted outside the app gate (standalone
  /// Settings hosts used by tests).
  static LicenseScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LicenseScope>();

  @override
  bool updateShouldNotify(LicenseScope oldWidget) =>
      state != oldWidget.state || refresh != oldWidget.refresh;
}
