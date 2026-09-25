// Schema migration v1 → v2.
//
// v2 is the release that introduced the offline license table. An existing
// installation must survive that upgrade untouched: every pre-license row is
// kept, the new `licenses` table appears (empty, ready for activation), and
// the schema version actually moves 1 → 2.
//
// The legacy database is built by a drift subclass pinned to `schemaVersion`
// 1 that creates the full v1 schema (everything except `licenses`) — exactly
// what an installed Taj 1.x wrote to disk.

import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import 'package:taj/data/local/app_database.dart';

/// The pre-license (v1) schema: every table except `licenses`.
class _LegacyDatabase extends AppDatabase {
  // `super.e` would target the unnamed constructor (production file path),
  // so the named super constructor has to be spelled out.
  // ignore: use_super_parameters
  _LegacyDatabase(QueryExecutor e) : super.forTesting(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await m.deleteTable(licenses.actualTableName);
        },
      );
}

Future<File> _tempDbFile() async {
  final dir = await Directory.systemTemp.createTemp('taj_license_migration_');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return File('${dir.path}/legacy.db');
}

/// v1 installations have no license storage at all.
Future<bool> _v1KnowsAboutLicenses(AppDatabase db) async {
  try {
    await db.getActiveLicense();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  test('v1 → v2 keeps legacy data and adds the license table', () async {
    final file = await _tempDbFile();

    // ── 1. An existing installation, still on v1 ──────────────────────────
    final legacy = _LegacyDatabase(NativeDatabase(file));
    expect(legacy.schemaVersion, 1);

    await legacy.insertBranch(BranchesCompanion.insert(
      id: 'b-legacy-1',
      name: 'الفرع الرئيسي',
      city: 'طرابلس',
    ));
    await legacy.insertBranch(BranchesCompanion.insert(
      id: 'b-legacy-2',
      name: 'فرع الزاوية',
      city: 'زاوية',
    ));

    expect(await _v1KnowsAboutLicenses(legacy), isFalse,
        reason: 'v1 has no licenses table');
    expect(await legacy.allBranches(), hasLength(2));
    await legacy.close();

    // ── 2. The same file opened by the current (v2) build ────────────────
    final db = AppDatabase.forTesting(NativeDatabase(file));
    expect(db.schemaVersion, 2);

    // Opening performs the upgrade as a side effect of the first query.
    final branches = await db.allBranches();
    expect(branches.map((b) => b.id), containsAll(['b-legacy-1', 'b-legacy-2']));
    expect(branches.firstWhere((b) => b.id == 'b-legacy-1').name,
        'الفرع الرئيسي');
    expect(branches.firstWhere((b) => b.id == 'b-legacy-1').city, 'طرابلس');

    // ── 3. The new table exists and is empty ─────────────────────────────
    expect(await db.getActiveLicense(), isNull);

    // ── 4. …and is fully usable for activation ───────────────────────────
    final now = DateTime.now().toUtc();
    await db.upsertLicense(
      id: 'lic_migrated_1',
      code: 'TAJ1.eyJ2IjoxfQ.signature',
      customerName: 'متجر النور',
      fingerprint: 'A1B2-C3D4-E5F6-0718-293A-4B5C-6D7E-8F90',
      planCode: 'taj_pos_pro',
      issuedAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 365)),
      activatedAt: now,
    );

    final stored = await db.getActiveLicense();
    expect(stored, isNotNull);
    expect(stored!.id, 'lic_migrated_1');
    expect(stored.customerName, 'متجر النور');
    expect(stored.planCode, 'taj_pos_pro');
    expect(stored.fingerprint, 'A1B2-C3D4-E5F6-0718-293A-4B5C-6D7E-8F90');
    expect(stored.expiresAt.difference(stored.issuedAt).inDays, 366);

    // A second activation replaces the first instead of stacking rows.
    await db.upsertLicense(
      id: 'lic_migrated_2',
      code: 'TAJ1.eyJ2IjoxfQ.other',
      customerName: 'متجر النور 2',
      fingerprint: 'A1B2-C3D4-E5F6-0718-293A-4B5C-6D7E-8F90',
      planCode: 'taj_lite',
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      activatedAt: now,
    );
    expect((await db.getActiveLicense())!.id, 'lic_migrated_2');

    await db.clearLicense();
    expect(await db.getActiveLicense(), isNull);

    // Legacy data is still there after all of that.
    expect(await db.allBranches(), hasLength(2));
    await db.close();

    // ── 5. SQLite itself reports the new schema version ──────────────────
    final conn = raw.sqlite3.open(file.path);
    try {
      final row = conn.select('PRAGMA user_version').first;
      expect(row['user_version'], 2, reason: 'user_version advanced 1 → 2');
      final tables = conn
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'])
          .toSet();
      expect(tables, contains('licenses'));
    } finally {
      conn.dispose();
    }
  });
}
