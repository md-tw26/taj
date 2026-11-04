import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'default_data.dart';
import 'demo_models.dart';

class DemoStore extends ChangeNotifier {
  /// [autoLoad] and [enablePersistence] exist for tests: a store built with
  /// `autoLoad: false` skips reading SharedPreferences (and the caller fills
  /// it directly — see `test/fixtures/sample_data.dart`), and one built with
  /// `enablePersistence: false` never writes to SharedPreferences. The real
  /// app never sets either, so its behavior is unchanged.
  DemoStore({bool autoLoad = true, bool enablePersistence = true})
    : _enablePersistence = enablePersistence {
    applyDefaultData(this);
    if (autoLoad) {
      load();
    } else {
      isLoading = false;
    }
  }

  final bool _enablePersistence;

  /// Name of the signed-in user, set by the app shell after login. Used as the
  /// actor on audit/journal/status records instead of a hard-coded name. Not
  /// persisted (it's session state, not business data).
  String currentUser = '';

  /// The actor to stamp on records: the signed-in user, or a neutral fallback
  /// if the session hasn't set one (e.g. during tests).
  String get _actor => currentUser.isEmpty ? 'مستخدم النظام' : currentUser;

  /// Next sequence number for a prefixed id (e.g. `INV-`), computed from the
  /// largest existing one so it never collides after a deletion (unlike a
  /// `length + 1` scheme). [floor] is the lowest number to start from.
  static String nextPrefixedId(
    Iterable<String> ids,
    String prefix, {
    int floor = 0,
  }) {
    var mx = floor;
    for (final id in ids) {
      if (id.startsWith(prefix)) {
        final n = int.tryParse(id.substring(prefix.length));
        if (n != null && n > mx) mx = n;
      }
    }
    return '$prefix${mx + 1}';
  }

  static const _storageKey = 'taj_store_v2';

  /// The pre-cleanup key. Its blob was demo data mixed with any real edits, so
  /// on first run of this version we delete it rather than migrate (decision 1
  /// in `TAJ-Remove-Demo-Data-Prompt.md`).
  static const _legacyStorageKey = 'taj_demo_store_v1';

  /// Where a blob we failed to decode is preserved, so a corrupt/incompatible
  /// save is never silently discarded or overwritten.
  static const _corruptBackupKey = 'taj_store_v2_corrupt_backup';
  bool isLoading = true;
  String? error;
  List<DemoBranch> branches = [];
  List<DemoProduct> products = [];
  List<DemoCustomer> customers = [];
  List<DemoSupplier> suppliers = [];
  List<DemoSale> sales = [];
  List<DemoPurchase> purchases = [];
  List<DemoExpense> expenses = [];
  List<DemoAccount> accounts = [];
  List<DemoTreasuryMovement> treasuryMovements = [];
  List<DemoLedgerAccount> ledgerAccounts = [];
  List<DemoJournalEntry> journalEntries = [];
  List<DemoAccountingAudit> accountingAudit = [];
  List<DemoEmployee> employees = [];
  List<DemoPayrollTxn> payrollTxns = [];
  List<DemoTerminal> terminals = [];
  List<DemoNotification> notifications = [];
  List<DemoUser> users = [];
  List<DemoStatusHistory> statusHistory = [];

  int get lowStockCount =>
      products.where((p) => p.stock <= p.reorderLevel).length;
  double get salesTotal => sales
      .where(
        (s) =>
            s.status != DemoSaleStatus.cancelled &&
            s.status != DemoSaleStatus.returned,
      )
      .fold(0, (sum, s) => sum + s.total);
  int get orderCount => sales.length;
  int get unreadNotifications => notifications.where((n) => !n.read).length;

  Future<void> markNotificationRead(String id) async {
    final target = notifications.where((n) => n.id == id && !n.read);
    if (target.isEmpty) return;
    notifications = [
      for (final n in notifications)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
    await _save();
    notifyListeners();
  }

  Future<void> toggleNotificationRead(String id) async {
    notifications = [
      for (final n in notifications)
        if (n.id == id) n.copyWith(read: !n.read) else n,
    ];
    await _save();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    if (notifications.every((n) => n.read)) return;
    notifications = [for (final n in notifications) n.copyWith(read: true)];
    await _save();
    notifyListeners();
  }

  Future<void> upsertUser(DemoUser user) async {
    final i = users.indexWhere((u) => u.id == user.id);
    if (i < 0) {
      users = [...users, user];
    } else {
      users = [
        for (final u in users)
          if (u.id == user.id) user else u,
      ];
    }
    await _save();
    notifyListeners();
  }

  Future<void> setUserActive(String id, bool active) async {
    users = [
      for (final u in users)
        if (u.id == id) u.copyWith(active: active) else u,
    ];
    await _save();
    notifyListeners();
  }

  List<double> get lastSevenDaySales {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index));
      return sales
          .where(
            (sale) =>
                sale.date.year == day.year &&
                sale.date.month == day.month &&
                sale.date.day == day.day &&
                sale.status != DemoSaleStatus.cancelled &&
                sale.status != DemoSaleStatus.returned,
          )
          .fold<double>(0, (sum, sale) => sum + sale.total);
    });
  }

  Map<String, double> get productSales {
    final result = <String, double>{};
    for (final sale in sales) {
      if (sale.status == DemoSaleStatus.cancelled ||
          sale.status == DemoSaleStatus.returned) {
        continue;
      }
      for (final line in sale.lines) {
        result[line.productId] = (result[line.productId] ?? 0) + line.total;
      }
    }
    return result;
  }

  double salesForBranch(String branchId) => sales
      .where(
        (s) =>
            s.branchId == branchId &&
            s.status != DemoSaleStatus.cancelled &&
            s.status != DemoSaleStatus.returned,
      )
      .fold(0, (sum, s) => sum + s.total);
  int terminalsForBranch(String branchId) =>
      terminals.where((t) => t.branchId == branchId).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // One-time cleanup: drop the old demo blob so its fake data never resurfaces.
    if (prefs.containsKey(_legacyStorageKey)) {
      await prefs.remove(_legacyStorageKey);
    }

    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      // Fresh install: keep the first-run defaults already applied.
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Don't silently replace data we couldn't read. Preserve the raw blob
      // under a backup key, surface the error, and block persistence so the
      // next edit can't overwrite the user's saved (if unreadable) data.
      await prefs.setString(_corruptBackupKey, raw);
      _loadFailed = true;
      error =
          'تعذّر قراءة البيانات المحفوظة. حُفظت نسخة منها، ولن يُكتب فوقها. '
          'راجع مدير النظام.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Set when [load] couldn't decode the saved blob. While true, [_save] is a
  /// no-op so the preserved (unreadable) data is never overwritten.
  bool _loadFailed = false;

  void _decode(Map<String, dynamic> j) {
    branches =
        (j['branches'] as List)
            .map(
              (e) => DemoBranch.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    products =
        (j['products'] as List)
            .map(
              (e) => DemoProduct.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    customers =
        (j['customers'] as List)
            .map(
              (e) => DemoCustomer.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    suppliers =
        (j['suppliers'] as List)
            .map(
              (e) => DemoSupplier.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    sales =
        (j['sales'] as List)
            .map((e) => DemoSale.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    purchases =
        (j['purchases'] as List)
            .map(
              (e) => DemoPurchase.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    expenses =
        (j['expenses'] as List)
            .map(
              (e) => DemoExpense.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    // Guarded so a persisted blob saved before the treasury module existed
    // keeps the default accounts/movements instead of being wiped to empty.
    if (j['accounts'] != null) {
      accounts =
          (j['accounts'] as List)
              .map(
                (e) =>
                    DemoAccount.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    }
    if (j['treasuryMovements'] != null) {
      treasuryMovements =
          (j['treasuryMovements'] as List)
              .map(
                (e) => DemoTreasuryMovement.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    if (j['ledgerAccounts'] != null) {
      ledgerAccounts =
          (j['ledgerAccounts'] as List)
              .map(
                (e) => DemoLedgerAccount.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    if (j['journalEntries'] != null) {
      journalEntries =
          (j['journalEntries'] as List)
              .map(
                (e) => DemoJournalEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    if (j['accountingAudit'] != null) {
      accountingAudit =
          (j['accountingAudit'] as List)
              .map(
                (e) => DemoAccountingAudit.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    if (j['employees'] != null) {
      employees =
          (j['employees'] as List)
              .map(
                (e) =>
                    DemoEmployee.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    }
    if (j['payrollTxns'] != null) {
      payrollTxns =
          (j['payrollTxns'] as List)
              .map(
                (e) => DemoPayrollTxn.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
    }
    terminals =
        (j['terminals'] as List)
            .map(
              (e) => DemoTerminal.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    notifications =
        (j['notifications'] as List)
            .map(
              (e) => DemoNotification.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
    users =
        (j['users'] as List? ?? [])
            .map((e) => DemoUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    statusHistory =
        (j['statusHistory'] as List? ?? [])
            .map(
              (e) => DemoStatusHistory.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
  }

  Future<void> _save() async {
    if (!_enablePersistence || _loadFailed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'branches': branches.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
        'customers': customers.map((e) => e.toJson()).toList(),
        'suppliers': suppliers.map((e) => e.toJson()).toList(),
        'sales': sales.map((e) => e.toJson()).toList(),
        'purchases': purchases.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'treasuryMovements': treasuryMovements.map((e) => e.toJson()).toList(),
        'ledgerAccounts': ledgerAccounts.map((e) => e.toJson()).toList(),
        'journalEntries': journalEntries.map((e) => e.toJson()).toList(),
        'accountingAudit': accountingAudit.map((e) => e.toJson()).toList(),
        'employees': employees.map((e) => e.toJson()).toList(),
        'payrollTxns': payrollTxns.map((e) => e.toJson()).toList(),
        'terminals': terminals.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'users': users.map((e) => e.toJson()).toList(),
        'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
      }),
    );
  }

  Future<void> addSale({
    required Map<String, int> quantities,
    required DemoPaymentMethod paymentMethod,
    String? customerId,
    String? branchId,
    double? totalOverride,
  }) async {
    if (quantities.isEmpty) {
      throw StateError('لا يمكن تسجيل بيع بسلة فارغة');
    }
    if (customerId != null &&
        !customers.any((customer) => customer.id == customerId)) {
      throw StateError('العميل غير موجود');
    }
    final resolvedBranchId = branchId ?? 'b1';
    if (!branches.any((branch) => branch.id == resolvedBranchId)) {
      throw StateError('الفرع غير موجود');
    }
    final lines = <DemoSaleLine>[];
    for (final entry in quantities.entries) {
      final p = products.firstWhere((item) => item.id == entry.key);
      if (entry.value <= 0 || p.stock < entry.value) {
        throw StateError('المخزون غير كافٍ للصنف ${p.name}');
      }
      lines.add(
        DemoSaleLine(
          productId: p.id,
          quantity: entry.value,
          unitPrice: p.price,
        ),
      );
    }
    final total =
        totalOverride ?? lines.fold<double>(0, (sum, line) => sum + line.total);
    products =
        products.map((p) {
          final qty = quantities[p.id] ?? 0;
          return qty == 0 ? p : p.copyWith(stock: p.stock - qty);
        }).toList();
    sales = [
      DemoSale(
        id: nextPrefixedId(sales.map((s) => s.id), 'INV-', floor: 1048),
        branchId: resolvedBranchId,
        date: DateTime.now(),
        lines: lines,
        total: total,
        status:
            paymentMethod == DemoPaymentMethod.credit
                ? DemoSaleStatus.credit
                : DemoSaleStatus.paid,
        paymentMethod: paymentMethod,
        customerId: customerId,
      ),
      ...sales,
    ];
    if (customerId != null && paymentMethod == DemoPaymentMethod.credit) {
      customers =
          customers
              .map(
                (customer) =>
                    customer.id == customerId
                        ? customer.copyWith(balance: customer.balance + total)
                        : customer,
              )
              .toList();
    }
    notifications = [
      DemoNotification(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        title: 'تم تسجيل بيع جديد',
        message:
            'الفاتورة ${sales.first.id} بقيمة ${total.toStringAsFixed(3)} د.ل',
        date: DateTime.now(),
      ),
      ...notifications,
    ];
    await _save();
    notifyListeners();
  }

  Future<void> adjustStock(String productId, int delta) async {
    products =
        products
            .map(
              (p) =>
                  p.id == productId
                      ? p.copyWith(stock: (p.stock + delta).clamp(0, 999999))
                      : p,
            )
            .toList();
    await _save();
    notifyListeners();
  }

  Future<void> upsertProduct(DemoProduct product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index < 0) {
      products = [...products, product];
    } else {
      final next = [...products]..[index] = product;
      products = next;
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    products = products.where((p) => p.id != id).toList();
    await _save();
    notifyListeners();
  }

  Future<void> upsertCustomer(DemoCustomer customer) async {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index < 0) {
      customers = [...customers, customer];
    } else {
      final next = [...customers]..[index] = customer;
      customers = next;
    }

    await _save();
    notifyListeners();
  }

  Future<void> addSupplier(DemoSupplier supplier) async {
    suppliers = [...suppliers, supplier];
    await _save();
    notifyListeners();
  }

  Future<void> updateSaleStatus(String id, DemoSaleStatus status) async {
    if (!sales.any((sale) => sale.id == id)) {
      throw StateError('الفاتورة غير موجودة');
    }
    sales =
        sales.map((s) => s.id == id ? s.copyWith(status: status) : s).toList();
    statusHistory = [
      DemoStatusHistory(
        id: 'h${DateTime.now().microsecondsSinceEpoch}',
        entityId: id,
        status: status.name,
        date: DateTime.now(),
        actor: _actor,
      ),
      ...statusHistory,
    ];
    await _save();
    notifyListeners();
  }

  Future<void> addExpense(DemoExpense expense) async {
    if (!branches.any((branch) => branch.id == expense.branchId)) {
      throw StateError('الفرع غير موجود');
    }
    expenses = [expense, ...expenses];
    await _save();
    notifyListeners();
  }

  Future<void> addPurchase(DemoPurchase purchase) async {
    if (!suppliers.any((supplier) => supplier.id == purchase.supplierId)) {
      throw StateError('المورد غير موجود');
    }
    purchases = [purchase, ...purchases];
    await _save();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Treasury & Banks
  // ---------------------------------------------------------------------------

  /// Live book balance of [accountId] — opening balance plus every movement.
  double accountBalance(String accountId) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    return treasuryMovements
        .where((m) => m.accountId == accountId)
        .fold<double>(account.openingBalance, (sum, m) => sum + m.signedAmount);
  }

  /// Statement balance — counts only reconciled movements. The difference from
  /// [accountBalance] is exactly the sum of the un-reconciled movements.
  double reconciledBalance(String accountId) {
    final account = accounts.firstWhere((a) => a.id == accountId);
    return treasuryMovements
        .where((m) => m.accountId == accountId && m.reconciled)
        .fold<double>(account.openingBalance, (sum, m) => sum + m.signedAmount);
  }

  /// Adds a single deposit / withdrawal / reconcile movement to an account.
  Future<void> addTreasuryMovement(DemoTreasuryMovement movement) async {
    if (!accounts.any((a) => a.id == movement.accountId)) {
      throw StateError('الحساب غير موجود');
    }
    treasuryMovements = [movement, ...treasuryMovements];
    await _save();
    notifyListeners();
  }

  /// Records a transfer between two accounts as a pair of movements — an
  /// outflow on [fromAccountId] and an inflow on [toAccountId] — sharing one
  /// reference, mirroring the double-entry a real journal would generate.
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String reference = '',
    String description = '',
    DateTime? date,
  }) async {
    if (fromAccountId == toAccountId) {
      throw StateError('لا يمكن التحويل إلى نفس الحساب');
    }
    if (!accounts.any((a) => a.id == fromAccountId) ||
        !accounts.any((a) => a.id == toAccountId)) {
      throw StateError('الحساب غير موجود');
    }
    if (amount <= 0) {
      throw StateError('المبلغ غير صالح');
    }
    final ref =
        reference.isEmpty
            ? nextPrefixedId(treasuryMovements.map((m) => m.id), 'TRF-')
            : reference;
    final when = date ?? DateTime.now();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final out = DemoTreasuryMovement(
      id: 'MOV-$stamp-o',
      accountId: fromAccountId,
      type: DemoMovementType.transfer,
      amount: amount,
      date: when,
      isInflow: false,
      reference: ref,
      description: description,
      counterAccountId: toAccountId,
    );
    final incoming = DemoTreasuryMovement(
      id: 'MOV-$stamp-i',
      accountId: toAccountId,
      type: DemoMovementType.transfer,
      amount: amount,
      date: when,
      isInflow: true,
      reference: ref,
      description: description,
      counterAccountId: fromAccountId,
    );
    treasuryMovements = [incoming, out, ...treasuryMovements];
    await _save();
    notifyListeners();
  }

  /// Flips a movement's statement-reconciled flag (used by the reconciliation
  /// view to clear or un-clear a line against the bank statement).
  Future<void> setMovementReconciled(String movementId, bool reconciled) async {
    treasuryMovements = [
      for (final m in treasuryMovements)
        if (m.id == movementId) m.copyWith(reconciled: reconciled) else m,
    ];
    await _save();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Accounting (double-entry)
  // ---------------------------------------------------------------------------

  /// Direct children of a chart-of-accounts node (or the roots when null),
  /// ordered by code.
  List<DemoLedgerAccount> ledgerChildren(String? parentId) =>
      (ledgerAccounts.where((a) => a.parentId == parentId).toList()
        ..sort((a, b) => a.code.compareTo(b.code)));

  /// A node with no children is a posting (leaf) account.
  bool isLeafAccount(String id) => !ledgerAccounts.any((a) => a.parentId == id);

  /// [id] plus all of its descendants — so a header account rolls up its whole
  /// subtree.
  Set<String> descendantIds(String id) {
    final result = <String>{id};
    var added = true;
    while (added) {
      added = false;
      for (final a in ledgerAccounts) {
        if (a.parentId != null &&
            result.contains(a.parentId) &&
            !result.contains(a.id)) {
          result.add(a.id);
          added = true;
        }
      }
    }
    return result;
  }

  /// Only posted (and reversed — their reversal negates them) entries affect
  /// balances; drafts do not.
  bool _countsForBalance(DemoJournalEntry e) =>
      e.status == DemoEntryStatus.posted ||
      e.status == DemoEntryStatus.reversed;

  /// Total debit and credit posted against [accountId] and its whole subtree.
  (double, double) ledgerDebitCredit(String accountId) {
    final ids = descendantIds(accountId);
    var d = 0.0, c = 0.0;
    for (final e in journalEntries) {
      if (!_countsForBalance(e)) continue;
      for (final l in e.lines) {
        if (ids.contains(l.accountId)) {
          d += l.debit;
          c += l.credit;
        }
      }
    }
    return (d, c);
  }

  /// Net balance of [accountId] (subtree): positive means a net debit.
  double ledgerBalance(String accountId) {
    final (d, c) = ledgerDebitCredit(accountId);
    return d - c;
  }

  /// Posted/reversed entries that touch [accountId] (exact account), oldest
  /// first — the raw material for the general ledger and account detail.
  List<DemoJournalEntry> entriesTouching(String accountId) =>
      journalEntries
          .where(
            (e) =>
                _countsForBalance(e) &&
                e.lines.any((l) => l.accountId == accountId),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  DemoLedgerAccount? ledgerAccountById(String id) {
    for (final a in ledgerAccounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  String _nextEntryNumber() {
    var max = 0;
    for (final e in journalEntries) {
      final m = RegExp(r'(\d+)').firstMatch(e.number);
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    return 'JV-${(max + 1).toString().padLeft(3, '0')}';
  }

  String get nextEntryNumber => _nextEntryNumber();

  void _appendAudit(
    String action,
    String entryNumber,
    String before,
    String after,
  ) {
    accountingAudit = [
      DemoAccountingAudit(
        id: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
        date: DateTime.now(),
        user: _actor,
        action: action,
        entryNumber: entryNumber,
        before: before,
        after: after,
      ),
      ...accountingAudit,
    ];
  }

  /// Creates a new journal entry (draft or posted).
  Future<void> addJournalEntry(DemoJournalEntry entry) async {
    if (entry.status == DemoEntryStatus.posted && !entry.isBalanced) {
      throw StateError('لا يمكن ترحيل قيد غير متوازن');
    }
    journalEntries = [entry, ...journalEntries];
    _appendAudit(
      'إنشاء',
      entry.number,
      '—',
      entry.status == DemoEntryStatus.posted ? 'مُرحّل' : 'مسودة',
    );
    await _save();
    notifyListeners();
  }

  /// Posts a draft entry — only if it balances.
  Future<void> postEntry(String id) async {
    final e = journalEntries.firstWhere((x) => x.id == id);
    if (!e.isBalanced) throw StateError('القيد غير متوازن');
    journalEntries = [
      for (final x in journalEntries)
        if (x.id == id) x.copyWith(status: DemoEntryStatus.posted) else x,
    ];
    _appendAudit('ترحيل', e.number, 'مسودة', 'مُرحّل');
    await _save();
    notifyListeners();
  }

  Future<void> reviewEntry(String id) async {
    final e = journalEntries.firstWhere((x) => x.id == id);
    journalEntries = [
      for (final x in journalEntries)
        if (x.id == id) x.copyWith(reviewed: true) else x,
    ];
    _appendAudit('مراجعة', e.number, 'غير مُراجَع', 'مُراجَع');
    await _save();
    notifyListeners();
  }

  Future<void> approveEntry(String id) async {
    final e = journalEntries.firstWhere((x) => x.id == id);
    journalEntries = [
      for (final x in journalEntries)
        if (x.id == id) x.copyWith(approved: true) else x,
    ];
    _appendAudit('اعتماد', e.number, 'غير معتمد', 'معتمد');
    await _save();
    notifyListeners();
  }

  /// Reverses a posted entry: marks it reversed and appends a new posted entry
  /// with debit/credit swapped, so the two together net to zero.
  Future<void> reverseEntry(String id) async {
    final e = journalEntries.firstWhere((x) => x.id == id);
    if (e.status != DemoEntryStatus.posted) {
      throw StateError('يمكن عكس القيود المُرحّلة فقط');
    }
    final revNumber = _nextEntryNumber();
    final reversal = DemoJournalEntry(
      id: revNumber,
      number: revNumber,
      date: DateTime.now(),
      description: 'عكس القيد ${e.number}',
      status: DemoEntryStatus.posted,
      reviewed: true,
      approved: true,
      createdBy: _actor,
      reversalOfId: e.id,
      lines: [
        for (final l in e.lines)
          DemoJournalLine(
            accountId: l.accountId,
            debit: l.credit,
            credit: l.debit,
            description: 'عكس: ${l.description}',
          ),
      ],
    );
    journalEntries = [
      reversal,
      for (final x in journalEntries)
        if (x.id == id) x.copyWith(status: DemoEntryStatus.reversed) else x,
    ];
    _appendAudit('عكس', e.number, 'مُرحّل', 'معكوس — أُنشئ القيد $revNumber');
    await _save();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Employees & Payroll
  // ---------------------------------------------------------------------------

  DemoEmployee? employeeById(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Advances + withdrawals recorded against [employeeId] in [month] (defaults
  /// to the current month).
  List<DemoPayrollTxn> payrollTxnsFor(String employeeId, {DateTime? month}) {
    final m = month ?? DateTime.now();
    return payrollTxns
        .where(
          (t) =>
              t.employeeId == employeeId &&
              t.date.year == m.year &&
              t.date.month == m.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double advancesTotal(String employeeId, {DateTime? month}) =>
      payrollTxnsFor(employeeId, month: month)
          .where((t) => t.type == DemoPayrollTxnType.advance)
          .fold<double>(0, (s, t) => s + t.amount);

  double withdrawalsTotal(String employeeId, {DateTime? month}) =>
      payrollTxnsFor(employeeId, month: month)
          .where((t) => t.type == DemoPayrollTxnType.withdrawal)
          .fold<double>(0, (s, t) => s + t.amount);

  /// Total deductions for the period = fixed deductions + advances + withdrawals.
  double employeeDeductionsTotal(String employeeId, {DateTime? month}) {
    final e = employeeById(employeeId);
    if (e == null) return 0;
    return e.deductions +
        advancesTotal(employeeId, month: month) +
        withdrawalsTotal(employeeId, month: month);
  }

  /// Net pay = gross earnings − total deductions.
  double employeeNet(String employeeId, {DateTime? month}) {
    final e = employeeById(employeeId);
    if (e == null) return 0;
    return e.grossEarnings - employeeDeductionsTotal(employeeId, month: month);
  }

  /// Salary expenses (category مرتبات) linked to [employeeId].
  List<DemoExpense> linkedExpensesFor(String employeeId) =>
      expenses.where((x) => x.employeeId == employeeId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Whether the employee has a salary payment recorded in [month].
  bool isSalaryPaid(String employeeId, {DateTime? month}) {
    final m = month ?? DateTime.now();
    return expenses.any(
      (x) =>
          x.employeeId == employeeId &&
          x.category == 'مرتبات' &&
          x.date.year == m.year &&
          x.date.month == m.month,
    );
  }

  Future<void> addEmployee(DemoEmployee employee) async {
    employees = [employee, ...employees];
    await _save();
    notifyListeners();
  }

  Future<void> updateEmployee(DemoEmployee employee) async {
    employees = [
      for (final e in employees)
        if (e.id == employee.id) employee else e,
    ];
    await _save();
    notifyListeners();
  }

  String get nextEmployeeId {
    var max = 0;
    for (final e in employees) {
      final n = int.tryParse(e.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (n > max) max = n;
    }
    return 'E${max + 1}';
  }

  Future<void> addPayrollTxn(DemoPayrollTxn txn) async {
    if (!employees.any((e) => e.id == txn.employeeId)) {
      throw StateError('الموظف غير موجود');
    }
    payrollTxns = [txn, ...payrollTxns];
    await _save();
    notifyListeners();
  }

  /// Pays an employee's net salary for [month]: records a linked salary expense
  /// (category مرتبات) which is what marks the employee paid and feeds the
  /// expenses ledger. Reuses [addExpense] so the expense link stays consistent.
  Future<void> paySalary(String employeeId, {DateTime? month}) async {
    final e = employeeById(employeeId);
    if (e == null) throw StateError('الموظف غير موجود');
    final m = month ?? DateTime.now();
    if (isSalaryPaid(employeeId, month: m)) return;
    final net = employeeNet(employeeId, month: m);
    expenses = [
      DemoExpense(
        id: 'EXP-${DateTime.now().microsecondsSinceEpoch}',
        category: 'مرتبات',
        amount: net,
        date: m,
        branchId: e.branchId,
        method: DemoPaymentMethod.bank,
        employeeId: employeeId,
      ),
      ...expenses,
    ];
    await _save();
    notifyListeners();
  }
}
