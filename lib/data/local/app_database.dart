// TODO: Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`
// to generate app_database.g.dart. This file will not compile until that step is done.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ── Table definitions ───────────────────────────────────────────────────────

@DataClassName('Branch')
class Branches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get city => text().withLength(min: 1, max: 100)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Roles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(max: 500).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Permissions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(max: 500).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RolePermissions extends Table {
  TextColumn get roleId => text().references(Roles, #id)();
  TextColumn get permissionId => text().references(Permissions, #id)();

  @override
  Set<Column> get primaryKey => {roleId, permissionId};
}

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get email => text().withLength(min: 1, max: 200)();
  TextColumn get passwordHash => text()();
  TextColumn get roleId => text().references(Roles, #id)();
  TextColumn get branchId => text().references(Branches, #id)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Uoms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get symbol => text().withLength(min: 1, max: 10)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ItemCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withLength(max: 500).nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().withLength(max: 50).nullable()();
  TextColumn get categoryId => text().references(ItemCategories, #id)();
  TextColumn get uomId => text().references(Uoms, #id)();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  // Denormalised cache — only updated inside the same transaction as a
  // StockLedgerEntry insert (see taj-erp-skill.md append-only ledger rule).
  // Never write to this column directly via updateItem.
  IntColumn get stockQty => integer().withDefault(const Constant(0))();
  IntColumn get reorderLevel => integer().withDefault(const Constant(0))();
  TextColumn get iconCode => text().withLength(max: 50).nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('LYD'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PriceListItems extends Table {
  TextColumn get priceListId => text().references(PriceLists, #id)();
  TextColumn get itemId => text().references(Items, #id)();
  RealColumn get price => real()();

  @override
  Set<Column> get primaryKey => {priceListId, itemId};
}

class Warehouses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get branchId => text().references(Branches, #id)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class StockLedgerEntries extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  RealColumn get qtyChange => real()();
  RealColumn get balanceAfter => real()();
  TextColumn get voucherType => text().withLength(min: 1, max: 50)();
  TextColumn get voucherId => text()();
  TextColumn get batchNo => text().nullable()();
  TextColumn get reversalOf => text().nullable()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get postingDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// The single active offline license. There is never more than one row: the
/// activation flow deletes any previous row(s) before inserting the new one.
@DataClassName('LicenseRecord')
class Licenses extends Table {
  TextColumn get id => text()(); // primary key ('lic_<millis>_<rand>')
  TextColumn get code => text()(); // full signed TAJ1... string
  TextColumn get customerName => text()();
  TextColumn get fingerprint => text()();
  TextColumn get planCode => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get activatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Branches,
    Roles,
    Permissions,
    RolePermissions,
    Users,
    Uoms,
    ItemCategories,
    Items,
    PriceLists,
    PriceListItems,
    Warehouses,
    StockLedgerEntries,
    Licenses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Allow creating an in-memory instance for tests.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: add the offline-license table only. Every v1 table (and
          // therefore all existing user data) is left completely untouched.
          if (from < 2) await m.createTable(licenses);
        },
      );

  // ── Branch CRUD ──────────────────────────────────────────────────────────

  Future<List<Branch>> allBranches() => select(branches).get();

  Stream<List<Branch>> watchAllBranches() => select(branches).watch();

  Future<Branch> branchById(String id) =>
      (select(branches)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertBranch(BranchesCompanion entry) =>
      into(branches).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateBranch(BranchesCompanion entry) =>
      update(branches).replace(entry);

  Future<int> deleteBranch(String id) =>
      (delete(branches)..where((t) => t.id.equals(id))).go();

  // ── Role CRUD ─────────────────────────────────────────────────────────────

  Future<List<Role>> allRoles() => select(roles).get();

  Stream<List<Role>> watchAllRoles() => select(roles).watch();

  Future<Role> roleById(String id) =>
      (select(roles)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertRole(RolesCompanion entry) =>
      into(roles).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateRole(RolesCompanion entry) =>
      update(roles).replace(entry);

  Future<int> deleteRole(String id) =>
      (delete(roles)..where((t) => t.id.equals(id))).go();

  // ── Permission CRUD ───────────────────────────────────────────────────────

  Future<List<Permission>> allPermissions() => select(permissions).get();

  Stream<List<Permission>> watchAllPermissions() =>
      select(permissions).watch();

  Future<int> insertPermission(PermissionsCompanion entry) =>
      into(permissions).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> deletePermission(String id) =>
      (delete(permissions)..where((t) => t.id.equals(id))).go();

  // ── Role ↔ Permission ────────────────────────────────────────────────────

  Future<List<Role>> rolesForPermission(String permissionId) async {
    final query = select(roles).join([
      innerJoin(rolePermissions, rolePermissions.roleId.equalsExp(roles.id)),
    ])..where(rolePermissions.permissionId.equals(permissionId));
    return query.map((row) => row.readTable(roles)).get();
  }

  Stream<List<Permission>> watchPermissionsForRole(String roleId) {
    final query = select(permissions).join([
      innerJoin(
          rolePermissions, rolePermissions.permissionId.equalsExp(permissions.id)),
    ])..where(rolePermissions.roleId.equals(roleId));
    return query.map((row) => row.readTable(permissions)).watch();
  }

  Future<void> setRolePermissions(
      String roleId, List<String> permissionIds) async {
    await transaction(() async {
      await (delete(rolePermissions)
            ..where((t) => t.roleId.equals(roleId)))
          .go();
      for (final pid in permissionIds) {
        await into(rolePermissions).insert(
          RolePermissionsCompanion.insert(roleId: roleId, permissionId: pid),
        );
      }
    });
  }

  // ── User CRUD ─────────────────────────────────────────────────────────────

  Future<List<User>> allUsers() => select(users).get();

  Stream<List<User>> watchAllUsers() => select(users).watch();

  Future<User> userById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingle();

  Future<User?> userByEmail(String email) async {
    final results = await (select(users)..where((t) => t.email.equals(email)))
        .get();
    return results.isEmpty ? null : results.first;
  }

  Future<int> insertUser(UsersCompanion entry) =>
      into(users).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateUser(UsersCompanion entry) =>
      update(users).replace(entry);

  Future<int> deleteUser(String id) =>
      (delete(users)..where((t) => t.id.equals(id))).go();

  // ── UOM CRUD ──────────────────────────────────────────────────────────────

  Future<List<Uom>> allUoms() => select(uoms).get();

  Stream<List<Uom>> watchAllUoms() => select(uoms).watch();

  Future<Uom> uomById(String id) =>
      (select(uoms)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertUom(UomsCompanion entry) =>
      into(uoms).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateUom(UomsCompanion entry) =>
      update(uoms).replace(entry);

  Future<int> deleteUom(String id) =>
      (delete(uoms)..where((t) => t.id.equals(id))).go();

  // ── Item Category CRUD ────────────────────────────────────────────────────

  Future<List<ItemCategory>> allItemCategories() =>
      select(itemCategories).get();

  Stream<List<ItemCategory>> watchAllItemCategories() =>
      select(itemCategories).watch();

  Future<ItemCategory> itemCategoryById(String id) =>
      (select(itemCategories)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertItemCategory(ItemCategoriesCompanion entry) =>
      into(itemCategories).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateItemCategory(ItemCategoriesCompanion entry) =>
      update(itemCategories).replace(entry);

  Future<int> deleteItemCategory(String id) =>
      (delete(itemCategories)..where((t) => t.id.equals(id))).go();

  // ── Item CRUD ─────────────────────────────────────────────────────────────

  Future<List<Item>> allItems() => select(items).get();

  Stream<List<Item>> watchAllItems() => select(items).watch();

  Future<Item> itemById(String id) =>
      (select(items)..where((t) => t.id.equals(id))).getSingle();

  Future<Item?> itemByBarcode(String barcode) async {
    final results =
        await (select(items)..where((t) => t.barcode.equals(barcode))).get();
    return results.isEmpty ? null : results.first;
  }

  Future<int> insertItem(ItemsCompanion entry) =>
      into(items).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateItem(ItemsCompanion entry) =>
      update(items).replace(entry);

  Future<int> deleteItem(String id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  // ── Price List CRUD ───────────────────────────────────────────────────────

  Future<List<PriceList>> allPriceLists() => select(priceLists).get();

  Stream<List<PriceList>> watchAllPriceLists() => select(priceLists).watch();

  Future<PriceList> priceListById(String id) =>
      (select(priceLists)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertPriceList(PriceListsCompanion entry) =>
      into(priceLists).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> deletePriceList(String id) =>
      (delete(priceLists)..where((t) => t.id.equals(id))).go();

  // ── Price List Item CRUD ──────────────────────────────────────────────────

  Future<List<PriceListItem>> itemsForPriceList(String priceListId) =>
      (select(priceListItems)
            ..where((t) => t.priceListId.equals(priceListId)))
          .get();

  Stream<List<PriceListItem>> watchItemsForPriceList(String priceListId) =>
      (select(priceListItems)
            ..where((t) => t.priceListId.equals(priceListId)))
          .watch();

  Future<double?> itemPrice(String priceListId, String itemId) async {
    final results = await (select(priceListItems)
          ..where((t) =>
              t.priceListId.equals(priceListId) & t.itemId.equals(itemId)))
        .get();
    return results.isEmpty ? null : results.first.price;
  }

  Future<void> createPriceListVersion({
    required String oldPriceListId,
    required String newPriceListId,
    required String name,
  }) async {
    await transaction(() async {
      // 1. Copy all items from old list to new list
      final oldItems = await (select(priceListItems)
            ..where((t) => t.priceListId.equals(oldPriceListId)))
          .get();
      for (final item in oldItems) {
        await into(priceListItems).insert(PriceListItemsCompanion.insert(
          priceListId: newPriceListId,
          itemId: item.itemId,
          price: item.price,
        ));
      }
      // 2. Insert the new PriceLists row
      await into(priceLists).insert(PriceListsCompanion.insert(
        id: newPriceListId,
        name: name,
      ));
      // 3. Deactivate the old PriceLists row
      await (update(priceLists)
            ..where((t) => t.id.equals(oldPriceListId)))
          .write(const PriceListsCompanion(active: Value(false)));
    });
  }

  Future<int> deletePriceListItem(String priceListId, String itemId) =>
      (delete(priceListItems)
            ..where((t) =>
                t.priceListId.equals(priceListId) & t.itemId.equals(itemId)))
          .go();

  // ── Warehouse CRUD ────────────────────────────────────────────────────────

  Future<List<Warehouse>> allWarehouses() => select(warehouses).get();

  Stream<List<Warehouse>> watchAllWarehouses() => select(warehouses).watch();

  Future<Warehouse> warehouseById(String id) =>
      (select(warehouses)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertWarehouse(WarehousesCompanion entry) =>
      into(warehouses).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateWarehouse(WarehousesCompanion entry) =>
      update(warehouses).replace(entry);

  Future<int> deleteWarehouse(String id) =>
      (delete(warehouses)..where((t) => t.id.equals(id))).go();

  // ── Stock Ledger Entry (append-only) ──────────────────────────────────────
  // No updateStockLedgerEntry or deleteStockLedgerEntry methods exist.
  // Corrections are reversal entries that reference the original via reversalOf.

  Future<List<StockLedgerEntry>> allStockLedgerEntries() =>
      select(stockLedgerEntries).get();

  Stream<List<StockLedgerEntry>> watchAllStockLedgerEntries() =>
      select(stockLedgerEntries).watch();

  Future<List<StockLedgerEntry>> stockLedgerEntriesForItem(String itemId) =>
      (select(stockLedgerEntries)
            ..where((t) => t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.postingDate)]))
          .get();

  Future<List<StockLedgerEntry>> stockLedgerEntriesForWarehouse(
          String warehouseId) =>
      (select(stockLedgerEntries)
            ..where((t) => t.warehouseId.equals(warehouseId))
            ..orderBy([(t) => OrderingTerm.desc(t.postingDate)]))
          .get();

  Future<StockLedgerEntry> stockLedgerEntryById(String id) =>
      (select(stockLedgerEntries)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertStockLedgerEntry(StockLedgerEntriesCompanion entry) =>
      into(stockLedgerEntries).insert(entry);

  Future<double> currentStockBalance(String itemId, String warehouseId) async {
    final entries = await (select(stockLedgerEntries)
          ..where((t) =>
              t.itemId.equals(itemId) & t.warehouseId.equals(warehouseId)))
        .get();
    return entries.fold<double>(0, (sum, e) => sum + e.qtyChange);
  }

  // ── License (offline activation gate) ─────────────────────────────────────

  /// Persists the single active license: any previous row(s) are removed first,
  /// so the table never holds more than one record.
  Future<void> upsertLicense({
    required String id,
    required String code,
    required String customerName,
    required String fingerprint,
    required String planCode,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required DateTime activatedAt,
  }) async {
    await transaction(() async {
      await delete(licenses).go();
      await into(licenses).insert(LicensesCompanion.insert(
        id: id,
        code: code,
        customerName: customerName,
        fingerprint: fingerprint,
        planCode: planCode,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        activatedAt: activatedAt,
      ));
    });
  }

  /// The stored license row, or `null` when the device is not activated.
  Future<LicenseRecord?> getActiveLicense() async {
    final rows = await (select(licenses)..limit(1)).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Removes the stored license (deactivation).
  Future<void> clearLicense() async {
    await delete(licenses).go();
  }
}

// ── Connection ──────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'taj.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
