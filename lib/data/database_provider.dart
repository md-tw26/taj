import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';

import 'local/app_database.dart';

class DatabaseProvider extends InheritedWidget {
  const DatabaseProvider({
    super.key,
    required AppDatabase db,
    required super.child,
  })  : _db = db;

  final AppDatabase _db;

  /// Lazily-created empty database used when no provider is in scope.
  ///
  /// The app always mounts its screens under a [DatabaseProvider]; isolated
  /// widget hosts (responsive tests, previews, single-screen tooling) often do
  /// not. Screens that read branches/roles in a post-frame callback would
  /// otherwise crash instead of rendering their (data-less) state, so they get
  /// an empty in-memory database instead.
  static AppDatabase? _fallback;

  static AppDatabase _fallbackDatabase() =>
      _fallback ??= AppDatabase.forTesting(NativeDatabase.memory());

  static AppDatabase of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DatabaseProvider>();
    return provider?._db ?? _fallbackDatabase();
  }

  @override
  bool updateShouldNotify(DatabaseProvider oldWidget) => _db != oldWidget._db;
}
