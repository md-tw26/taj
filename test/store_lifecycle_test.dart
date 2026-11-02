// Store lifecycle: fresh install, persistence round-trip, legacy-key migration
// and corrupt-blob protection. These lock in the demo-data-removal contract
// (TAJ-Remove-Demo-Data-Prompt.md §6): a clean install starts empty-but-usable,
// the old demo blob is dropped, and unreadable saved data is never overwritten.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taj/core/demo/demo_models.dart';
import 'package:taj/core/demo/demo_store.dart';

const _v2Key = 'taj_store_v2';
const _v1Key = 'taj_demo_store_v1';
const _backupKey = 'taj_store_v2_corrupt_backup';

Future<DemoStore> _loadedStore() async {
  final store = DemoStore();
  // Let load() finish (it awaits SharedPreferences then notifies).
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install: empty but usable, with first-run defaults only', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await _loadedStore();

    expect(store.error, isNull);
    // Minimal operational defaults: one branch, one cash account, the COA.
    expect(store.branches.map((b) => b.id), ['b1']);
    expect(store.accounts.length, 1);
    expect(store.accounts.single.openingBalance, 0);
    expect(store.ledgerAccounts, isNotEmpty);
    // No fabricated business data.
    expect(store.products, isEmpty);
    expect(store.customers, isEmpty);
    expect(store.sales, isEmpty);
    expect(store.employees, isEmpty);
    expect(store.notifications, isEmpty);

    // Add a product, then sell it from the default branch — the core flow works.
    await store.upsertProduct(
      const DemoProduct(
        id: 'x1',
        name: 'صنف اختبار',
        barcode: '1',
        category: 'عام',
        price: 100,
        cost: 60,
        stock: 10,
        reorderLevel: 2,
        iconCode: 'spa',
      ),
    );
    await store.addSale(
      quantities: {'x1': 2},
      paymentMethod: DemoPaymentMethod.cash,
    );
    expect(store.sales, hasLength(1));
    expect(store.salesTotal, 200);
  });

  test('persistence round-trip: a new store restores saved data', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await _loadedStore();
    await a.upsertProduct(
      const DemoProduct(
        id: 'x1',
        name: 'صنف محفوظ',
        barcode: '1',
        category: 'عام',
        price: 100,
        cost: 60,
        stock: 10,
        reorderLevel: 2,
        iconCode: 'spa',
      ),
    );
    await a.addSale(
      quantities: {'x1': 1},
      paymentMethod: DemoPaymentMethod.cash,
    );

    final b = await _loadedStore();
    expect(b.products.map((p) => p.id), contains('x1'));
    expect(b.sales, hasLength(1));
  });

  test(
    'migration: the legacy demo blob is deleted and never surfaces',
    () async {
      // A v1 blob that (if migrated) would show a fake product.
      SharedPreferences.setMockInitialValues({
        _v1Key: jsonEncode({
          'branches': [
            {'id': 'b1', 'name': 'قديم', 'city': 'طرابلس'},
          ],
          'products': [
            {
              'id': 'old',
              'name': 'عود ملكي',
              'barcode': '1',
              'category': 'عطور',
              'price': 450,
              'cost': 300,
              'stock': 5,
              'reorderLevel': 2,
              'iconCode': 'spa',
            },
          ],
        }),
      });
      final store = await _loadedStore();

      expect(
        store.products,
        isEmpty,
        reason: 'legacy content must not migrate',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_v1Key), isFalse, reason: 'legacy key removed');
    },
  );

  test('corrupt blob: preserved, surfaced, and never overwritten', () async {
    SharedPreferences.setMockInitialValues({_v2Key: 'this is not json'});
    final store = await _loadedStore();

    expect(store.error, isNotNull);
    // Defaults still present (we didn't crash), but saved data left intact.
    expect(store.products, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(_backupKey),
      'this is not json',
      reason: 'raw blob preserved under backup key',
    );

    // A mutation must NOT overwrite the unreadable blob.
    await store.upsertProduct(
      const DemoProduct(
        id: 'x1',
        name: 'صنف',
        barcode: '1',
        category: 'عام',
        price: 100,
        cost: 60,
        stock: 10,
        reorderLevel: 2,
        iconCode: 'spa',
      ),
    );
    expect(
      prefs.getString(_v2Key),
      'this is not json',
      reason: 'persistence blocked while load failed',
    );
  });
}
