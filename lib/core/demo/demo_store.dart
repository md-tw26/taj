import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_models.dart';

class DemoStore extends ChangeNotifier {
  DemoStore() {
    _seed();
    load();
  }

  static const _storageKey = 'taj_demo_store_v1';
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
    try {
      await Future<void>.value();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _decode(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      error = 'تعذر تحميل بيانات العرض، تم استخدام البيانات التجريبية.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _seed() {
    branches = const [
      DemoBranch(id: 'b1', name: 'طرابلس - الفرع الرئيسي', city: 'طرابلس'),
      DemoBranch(id: 'b2', name: 'بنغازي - الفرع الشرقي', city: 'بنغازي'),
      DemoBranch(id: 'b3', name: 'مصراتة - السوق', city: 'مصراتة'),
      DemoBranch(id: 'b4', name: 'الزاوية - الفرع الغربي', city: 'الزاوية'),
    ];
    products = const [
      DemoProduct(
        id: 'p1',
        name: 'عود ملكي',
        barcode: '6224000111',
        category: 'عطور',
        price: 450,
        cost: 300,
        stock: 24,
        reorderLevel: 5,
        iconCode: 'spa',
      ),
      DemoProduct(
        id: 'p2',
        name: 'عطر المسك',
        barcode: '6224000112',
        category: 'عطور',
        price: 320,
        cost: 210,
        stock: 3,
        reorderLevel: 5,
        iconCode: 'local_florist',
      ),
      DemoProduct(
        id: 'p3',
        name: 'بخور فاخر',
        barcode: '6224000113',
        category: 'بخور',
        price: 180,
        cost: 110,
        stock: 57,
        reorderLevel: 8,
        iconCode: 'fire',
      ),
      DemoProduct(
        id: 'p4',
        name: 'ماء الورد',
        barcode: '6224000114',
        category: 'زيوت',
        price: 60,
        cost: 35,
        stock: 0,
        reorderLevel: 5,
        iconCode: 'water',
      ),
      DemoProduct(
        id: 'p5',
        name: 'دهن العود',
        barcode: '6224000115',
        category: 'زيوت',
        price: 700,
        cost: 520,
        stock: 12,
        reorderLevel: 4,
        iconCode: 'oil',
      ),
      DemoProduct(
        id: 'p6',
        name: 'عنبر',
        barcode: '6224000116',
        category: 'عطور',
        price: 540,
        cost: 390,
        stock: 2,
        reorderLevel: 5,
        iconCode: 'gift',
      ),
      DemoProduct(
        id: 'p7',
        name: 'مبخرة نحاس',
        barcode: '6224000117',
        category: 'هدايا',
        price: 240,
        cost: 160,
        stock: 18,
        reorderLevel: 5,
        iconCode: 'gift',
      ),
      DemoProduct(
        id: 'p8',
        name: 'بخور معمول',
        barcode: '6224000118',
        category: 'بخور',
        price: 150,
        cost: 90,
        stock: 40,
        reorderLevel: 8,
        iconCode: 'fire',
      ),
      DemoProduct(
        id: 'p9',
        name: 'زيت الصندل',
        barcode: '6224000119',
        category: 'زيوت',
        price: 210,
        cost: 140,
        stock: 5,
        reorderLevel: 5,
        iconCode: 'oil',
      ),
      DemoProduct(
        id: 'p10',
        name: 'طقم هدايا',
        barcode: '6224000120',
        category: 'هدايا',
        price: 380,
        cost: 250,
        stock: 9,
        reorderLevel: 4,
        iconCode: 'gift',
      ),
      DemoProduct(
        id: 'p11',
        name: 'مسك أبيض',
        barcode: '6224000121',
        category: 'عطور',
        price: 260,
        cost: 170,
        stock: 33,
        reorderLevel: 5,
        iconCode: 'local_florist',
      ),
      DemoProduct(
        id: 'p12',
        name: 'عود كمبودي',
        barcode: '6224000122',
        category: 'بخور',
        price: 820,
        cost: 600,
        stock: 0,
        reorderLevel: 3,
        iconCode: 'spa',
      ),
    ];
    customers = const [
      DemoCustomer(
        id: 'c1',
        name: 'سالم المبروك',
        phone: '0912345678',
        creditLimit: 2000,
        balance: 450,
      ),
      DemoCustomer(
        id: 'c2',
        name: 'نور الهدى',
        phone: '0923456789',
        creditLimit: 1500,
        balance: 1200,
      ),
      DemoCustomer(
        id: 'c3',
        name: 'خالد عمر',
        phone: '0934567890',
        creditLimit: 1000,
      ),
      DemoCustomer(
        id: 'c4',
        name: 'ليان أحمد',
        phone: '0945678901',
        creditLimit: 1000,
        balance: -320,
      ),
    ];
    suppliers = const [
      DemoSupplier(
        id: 's1',
        name: 'مؤسسة العطور',
        phone: '0911122334',
        balance: 5400,
      ),
      DemoSupplier(id: 's2', name: 'مستودع البخور', phone: '0922233445'),
      DemoSupplier(
        id: 's3',
        name: 'شركة الزيوت',
        phone: '0933344556',
        balance: 2100,
      ),
    ];
    final now = DateTime.now();
    sales = [
      DemoSale(
        id: 'INV-1048',
        branchId: 'b1',
        date: now.subtract(const Duration(days: 1)),
        lines: const [
          DemoSaleLine(productId: 'p1', quantity: 1, unitPrice: 450),
        ],
        total: 450,
        status: DemoSaleStatus.paid,
        paymentMethod: DemoPaymentMethod.cash,
        customerId: 'c1',
      ),
      DemoSale(
        id: 'INV-1047',
        branchId: 'b2',
        date: now.subtract(const Duration(days: 2)),
        lines: const [
          DemoSaleLine(productId: 'p3', quantity: 2, unitPrice: 180),
          DemoSaleLine(productId: 'p2', quantity: 2, unitPrice: 320),
        ],
        total: 1000,
        status: DemoSaleStatus.credit,
        paymentMethod: DemoPaymentMethod.credit,
        customerId: 'c2',
      ),
      DemoSale(
        id: 'INV-1046',
        branchId: 'b1',
        date: now.subtract(const Duration(days: 3)),
        lines: const [
          DemoSaleLine(productId: 'p7', quantity: 1, unitPrice: 240),
          DemoSaleLine(productId: 'p9', quantity: 1, unitPrice: 210),
        ],
        total: 450,
        status: DemoSaleStatus.paid,
        paymentMethod: DemoPaymentMethod.card,
      ),
    ];
    purchases = [
      DemoPurchase(
        id: 'PUR-210',
        supplierId: 's1',
        date: now.subtract(const Duration(days: 4)),
        total: 5400,
        paid: false,
      ),
    ];
    expenses = [
      DemoExpense(
        id: 'EXP-001',
        category: 'إيجار',
        amount: 3000,
        date: now.subtract(const Duration(days: 10)),
        branchId: 'b1',
        method: DemoPaymentMethod.bank,
      ),
      DemoExpense(
        id: 'EXP-SAL-E2',
        category: 'مرتبات',
        amount: 3300,
        date: DateTime(now.year, now.month, 1),
        branchId: 'b1',
        method: DemoPaymentMethod.bank,
        employeeId: 'E2',
      ),
    ];
    accounts = const [
      DemoAccount(
        id: 'ACC-C1',
        name: 'الصندوق الرئيسي',
        type: DemoAccountType.cash,
        branchId: 'b1',
        openingBalance: 15000,
      ),
      DemoAccount(
        id: 'ACC-C2',
        name: 'صندوق بنغازي',
        type: DemoAccountType.cash,
        branchId: 'b2',
        openingBalance: 8000,
      ),
      DemoAccount(
        id: 'ACC-C3',
        name: 'صندوق مصراتة',
        type: DemoAccountType.cash,
        branchId: 'b3',
        openingBalance: 5000,
      ),
      DemoAccount(
        id: 'ACC-B1',
        name: 'مصرف الجمهورية',
        type: DemoAccountType.bank,
        branchId: 'b1',
        openingBalance: 250000,
        bankName: 'مصرف الجمهورية',
        accountNo: '0071-2298-114',
      ),
      DemoAccount(
        id: 'ACC-B2',
        name: 'مصرف التجارة والتنمية الوطني',
        type: DemoAccountType.bank,
        branchId: 'b1',
        openingBalance: 1284500.5,
        bankName: 'مصرف التجارة والتنمية',
        accountNo: '0043-9910-552',
      ),
    ];
    treasuryMovements = [
      DemoTreasuryMovement(
        id: 'MOV-009',
        accountId: 'ACC-B2',
        type: DemoMovementType.withdraw,
        amount: 15400.25,
        date: now.subtract(const Duration(days: 1)),
        isInflow: false,
        reference: 'CHK-1130',
        description: 'شيك مورد لم يُصرف بعد',
        reconciled: false,
      ),
      DemoTreasuryMovement(
        id: 'MOV-001',
        accountId: 'ACC-C1',
        type: DemoMovementType.deposit,
        amount: 3200,
        date: now.subtract(const Duration(days: 1)),
        isInflow: true,
        reference: 'REC-3391',
        description: 'مبيعات نقدية',
      ),
      DemoTreasuryMovement(
        id: 'MOV-002',
        accountId: 'ACC-C1',
        type: DemoMovementType.withdraw,
        amount: 1500,
        date: now.subtract(const Duration(days: 1)),
        isInflow: false,
        reference: 'EXP-014',
        description: 'مصروف صيانة',
      ),
      DemoTreasuryMovement(
        id: 'MOV-003b',
        accountId: 'ACC-B1',
        type: DemoMovementType.transfer,
        amount: 10000,
        date: now.subtract(const Duration(days: 2)),
        isInflow: true,
        reference: 'TRF-207',
        description: 'إيداع من الصندوق الرئيسي',
        counterAccountId: 'ACC-C1',
        reconciled: false,
      ),
      DemoTreasuryMovement(
        id: 'MOV-003a',
        accountId: 'ACC-C1',
        type: DemoMovementType.transfer,
        amount: 10000,
        date: now.subtract(const Duration(days: 2)),
        isInflow: false,
        reference: 'TRF-207',
        description: 'إيداع بنكي — مصرف الجمهورية',
        counterAccountId: 'ACC-B1',
      ),
      DemoTreasuryMovement(
        id: 'MOV-004',
        accountId: 'ACC-B2',
        type: DemoMovementType.deposit,
        amount: 750000,
        date: now.subtract(const Duration(days: 3)),
        isInflow: true,
        reference: 'REC-8800',
        description: 'تحصيل قيمة عقد توريد',
      ),
      DemoTreasuryMovement(
        id: 'MOV-005',
        accountId: 'ACC-B1',
        type: DemoMovementType.withdraw,
        amount: 42250.75,
        date: now.subtract(const Duration(days: 4)),
        isInflow: false,
        reference: 'CHK-1121',
        description: 'شيك مورد',
      ),
      DemoTreasuryMovement(
        id: 'MOV-006',
        accountId: 'ACC-C2',
        type: DemoMovementType.reconcile,
        amount: 120,
        date: now.subtract(const Duration(days: 5)),
        isInflow: true,
        reference: 'ADJ-01',
        description: 'تسوية فروق جرد الصندوق',
      ),
      DemoTreasuryMovement(
        id: 'MOV-007',
        accountId: 'ACC-C2',
        type: DemoMovementType.deposit,
        amount: 2600,
        date: now.subtract(const Duration(days: 6)),
        isInflow: true,
        reference: 'REC-3410',
        description: 'مبيعات نقدية',
      ),
      DemoTreasuryMovement(
        id: 'MOV-008',
        accountId: 'ACC-C3',
        type: DemoMovementType.withdraw,
        amount: 900,
        date: now.subtract(const Duration(days: 7)),
        isInflow: false,
        reference: 'EXP-021',
        description: 'نثريات',
      ),
    ];
    ledgerAccounts = const [
      // 1 Assets
      DemoLedgerAccount(
          id: '1', code: '1', name: 'الأصول', type: DemoLedgerAccountType.asset),
      DemoLedgerAccount(
          id: '11',
          code: '11',
          name: 'الأصول المتداولة',
          type: DemoLedgerAccountType.asset,
          parentId: '1'),
      DemoLedgerAccount(
          id: '1101',
          code: '1101',
          name: 'الصندوق',
          type: DemoLedgerAccountType.asset,
          parentId: '11'),
      DemoLedgerAccount(
          id: '1102',
          code: '1102',
          name: 'المصارف',
          type: DemoLedgerAccountType.asset,
          parentId: '11'),
      DemoLedgerAccount(
          id: '110201',
          code: '110201',
          name: 'مصرف الجمهورية',
          type: DemoLedgerAccountType.asset,
          parentId: '1102'),
      DemoLedgerAccount(
          id: '110202',
          code: '110202',
          name: 'مصرف التجارة والتنمية',
          type: DemoLedgerAccountType.asset,
          parentId: '1102'),
      DemoLedgerAccount(
          id: '1103',
          code: '1103',
          name: 'ذمم العملاء',
          type: DemoLedgerAccountType.asset,
          parentId: '11'),
      DemoLedgerAccount(
          id: '1104',
          code: '1104',
          name: 'المخزون',
          type: DemoLedgerAccountType.asset,
          parentId: '11'),
      // 12 Fixed assets
      DemoLedgerAccount(
          id: '12',
          code: '12',
          name: 'الأصول الثابتة',
          type: DemoLedgerAccountType.asset,
          parentId: '1'),
      DemoLedgerAccount(
          id: '1201',
          code: '1201',
          name: 'الأثاث والمعدات',
          type: DemoLedgerAccountType.asset,
          parentId: '12'),
      // Deep branch (depth 6) to stress tree indentation + long names.
      DemoLedgerAccount(
          id: '1203',
          code: '1203',
          name: 'أصول أخرى',
          type: DemoLedgerAccountType.asset,
          parentId: '12'),
      DemoLedgerAccount(
          id: '120301',
          code: '120301',
          name: 'المستوى الثالث',
          type: DemoLedgerAccountType.asset,
          parentId: '1203'),
      DemoLedgerAccount(
          id: '12030101',
          code: '12030101',
          name: 'المستوى الرابع',
          type: DemoLedgerAccountType.asset,
          parentId: '120301'),
      DemoLedgerAccount(
          id: '1203010101',
          code: '1203010101',
          name: 'المستوى الخامس',
          type: DemoLedgerAccountType.asset,
          parentId: '12030101'),
      DemoLedgerAccount(
          id: '120301010101',
          code: '120301010101',
          name: 'المستوى السادس - حساب بأسم عربي طويل جدًا لاختبار التداخل',
          type: DemoLedgerAccountType.asset,
          parentId: '1203010101'),
      // 2 Liabilities
      DemoLedgerAccount(
          id: '2',
          code: '2',
          name: 'الخصوم',
          type: DemoLedgerAccountType.liability),
      DemoLedgerAccount(
          id: '21',
          code: '21',
          name: 'الخصوم المتداولة',
          type: DemoLedgerAccountType.liability,
          parentId: '2'),
      DemoLedgerAccount(
          id: '2101',
          code: '2101',
          name: 'ذمم الموردين',
          type: DemoLedgerAccountType.liability,
          parentId: '21'),
      DemoLedgerAccount(
          id: '2102',
          code: '2102',
          name: 'مصلحة الضرائب',
          type: DemoLedgerAccountType.liability,
          parentId: '21'),
      // 3 Equity
      DemoLedgerAccount(
          id: '3',
          code: '3',
          name: 'حقوق الملكية',
          type: DemoLedgerAccountType.equity),
      DemoLedgerAccount(
          id: '3101',
          code: '3101',
          name: 'رأس المال',
          type: DemoLedgerAccountType.equity,
          parentId: '3'),
      DemoLedgerAccount(
          id: '3102',
          code: '3102',
          name: 'الأرباح المحتجزة',
          type: DemoLedgerAccountType.equity,
          parentId: '3'),
      // 4 Revenue
      DemoLedgerAccount(
          id: '4',
          code: '4',
          name: 'الإيرادات',
          type: DemoLedgerAccountType.revenue),
      DemoLedgerAccount(
          id: '4101',
          code: '4101',
          name: 'إيرادات المبيعات',
          type: DemoLedgerAccountType.revenue,
          parentId: '4'),
      DemoLedgerAccount(
          id: '4102',
          code: '4102',
          name: 'إيرادات أخرى',
          type: DemoLedgerAccountType.revenue,
          parentId: '4'),
      // 5 Expenses
      DemoLedgerAccount(
          id: '5',
          code: '5',
          name: 'المصروفات',
          type: DemoLedgerAccountType.expense),
      DemoLedgerAccount(
          id: '5101',
          code: '5101',
          name: 'تكلفة المبيعات',
          type: DemoLedgerAccountType.expense,
          parentId: '5'),
      DemoLedgerAccount(
          id: '5102',
          code: '5102',
          name: 'الرواتب والأجور',
          type: DemoLedgerAccountType.expense,
          parentId: '5'),
      DemoLedgerAccount(
          id: '5103',
          code: '5103',
          name: 'الإيجار',
          type: DemoLedgerAccountType.expense,
          parentId: '5'),
      DemoLedgerAccount(
          id: '5104',
          code: '5104',
          name: 'الكهرباء والماء',
          type: DemoLedgerAccountType.expense,
          parentId: '5'),
      DemoLedgerAccount(
          id: '5105',
          code: '5105',
          name: 'مصروفات أخرى',
          type: DemoLedgerAccountType.expense,
          parentId: '5'),
    ];
    journalEntries = [
      DemoJournalEntry(
        id: 'JV-001',
        number: 'JV-001',
        date: now.subtract(const Duration(days: 60)),
        description: 'إثبات رأس المال الافتتاحي عند تأسيس الشركة',
        status: DemoEntryStatus.posted,
        reviewed: true,
        approved: true,
        createdBy: 'أحمد الفيتوري',
        reference: 'CAP-01',
        attachments: const ['عقد_التأسيس.pdf'],
        lines: const [
          DemoJournalLine(accountId: '1101', debit: 100000, description: 'إيداع رأس المال'),
          DemoJournalLine(accountId: '3101', credit: 100000, description: 'رأس المال المدفوع'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-002',
        number: 'JV-002',
        date: now.subtract(const Duration(days: 30)),
        description: 'إثبات المبيعات النقدية لشهر يوليو',
        status: DemoEntryStatus.posted,
        reviewed: true,
        approved: true,
        createdBy: 'سميرة',
        reference: 'REC-3391',
        lines: const [
          DemoJournalLine(accountId: '1101', debit: 45000, description: 'تحصيل نقدي'),
          DemoJournalLine(accountId: '4101', credit: 45000, description: 'مبيعات'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-003',
        number: 'JV-003',
        date: now.subtract(const Duration(days: 25)),
        description: 'شراء أثاث ومعدات مكتبية من مصرف الجمهورية',
        status: DemoEntryStatus.posted,
        reviewed: true,
        createdBy: 'سميرة',
        reference: 'CHK-1121',
        lines: const [
          DemoJournalLine(accountId: '1201', debit: 22000, description: 'أثاث مكتبي'),
          DemoJournalLine(accountId: '110201', credit: 22000, description: 'شيك مصرفي'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-004',
        number: 'JV-004',
        date: now.subtract(const Duration(days: 20)),
        description: 'إثبات المصروفات التشغيلية لشهر يوليو (رواتب وإيجار وكهرباء)',
        status: DemoEntryStatus.posted,
        approved: true,
        createdBy: 'سميرة',
        reference: 'EXP-JUL',
        lines: const [
          DemoJournalLine(accountId: '5102', debit: 18000, description: 'رواتب الموظفين'),
          DemoJournalLine(accountId: '5103', debit: 6000, description: 'إيجار المحل'),
          DemoJournalLine(accountId: '5104', debit: 1500, description: 'كهرباء وماء'),
          DemoJournalLine(accountId: '110201', credit: 25500, description: 'سداد من المصرف'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-005',
        number: 'JV-005',
        date: now.subtract(const Duration(days: 2)),
        description: 'قيد تحت المراجعة — غير متوازن (للتوضيح)',
        status: DemoEntryStatus.draft,
        createdBy: 'محمد',
        lines: const [
          DemoJournalLine(accountId: '5105', debit: 3000, description: 'مصروف نثري'),
          DemoJournalLine(accountId: '1101', credit: 2500, description: 'صرف نقدي'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-006',
        number: 'JV-006',
        date: now.subtract(const Duration(days: 15)),
        description: 'مصروف تم تسجيله بالخطأ ثم عُكس',
        status: DemoEntryStatus.reversed,
        reviewed: true,
        createdBy: 'محمد',
        lines: const [
          DemoJournalLine(accountId: '5105', debit: 1200, description: 'مصروف مكرر'),
          DemoJournalLine(accountId: '1101', credit: 1200, description: 'صرف نقدي'),
        ],
      ),
      DemoJournalEntry(
        id: 'JV-007',
        number: 'JV-007',
        date: now.subtract(const Duration(days: 15)),
        description: 'عكس القيد JV-006',
        status: DemoEntryStatus.posted,
        reviewed: true,
        approved: true,
        createdBy: 'أحمد الفيتوري',
        reversalOfId: 'JV-006',
        lines: const [
          DemoJournalLine(accountId: '1101', debit: 1200, description: 'إعادة المبلغ'),
          DemoJournalLine(accountId: '5105', credit: 1200, description: 'إلغاء المصروف'),
        ],
      ),
    ];
    accountingAudit = [
      DemoAccountingAudit(
        id: 'AUD-1',
        date: now.subtract(const Duration(days: 60)),
        user: 'أحمد الفيتوري',
        action: 'ترحيل',
        entryNumber: 'JV-001',
        before: 'مسودة',
        after: 'مُرحّل',
      ),
      DemoAccountingAudit(
        id: 'AUD-2',
        date: now.subtract(const Duration(days: 59)),
        user: 'أحمد الفيتوري',
        action: 'اعتماد',
        entryNumber: 'JV-001',
        before: 'قيد المراجعة',
        after: 'معتمد',
      ),
      DemoAccountingAudit(
        id: 'AUD-3',
        date: now.subtract(const Duration(days: 15)),
        user: 'أحمد الفيتوري',
        action: 'عكس',
        entryNumber: 'JV-006',
        before: 'مُرحّل',
        after: 'معكوس — أُنشئ القيد JV-007',
      ),
    ];
    employees = [
      DemoEmployee(
        id: 'E1',
        name: 'طارق بن عمر',
        title: 'مدير عام',
        branchId: 'b1',
        hireDate: now.subtract(const Duration(days: 900)),
        phone: '0912000001',
        baseSalary: 4500,
        allowances: 800,
        bonuses: 500,
        deductions: 150,
      ),
      DemoEmployee(
        id: 'E2',
        name: 'سميرة المبروك',
        title: 'محاسبة',
        branchId: 'b1',
        hireDate: now.subtract(const Duration(days: 600)),
        phone: '0912000002',
        baseSalary: 3000,
        allowances: 400,
        bonuses: 200,
        deductions: 100,
      ),
      DemoEmployee(
        id: 'E3',
        name: 'محمد الأحمر',
        title: 'كاشير',
        branchId: 'b2',
        hireDate: now.subtract(const Duration(days: 400)),
        phone: '0912000003',
        baseSalary: 1800,
        allowances: 200,
        overtime: 150,
        deductions: 50,
      ),
      DemoEmployee(
        id: 'E4',
        name: 'عبد الرحمن الطاهر الفيتوري القذافي',
        title: 'مشرف مبيعات',
        branchId: 'b1',
        hireDate: now.subtract(const Duration(days: 300)),
        phone: '0912000004',
        baseSalary: 2500,
        allowances: 300,
        commissions: 600,
        deductions: 80,
      ),
      DemoEmployee(
        id: 'E5',
        name: 'فاطمة الزهراء',
        title: 'أمينة مخزن',
        branchId: 'b3',
        hireDate: now.subtract(const Duration(days: 200)),
        phone: '0912000005',
        baseSalary: 2000,
        allowances: 250,
        deductions: 60,
      ),
      DemoEmployee(
        id: 'E6',
        name: 'خالد سالم',
        title: 'سائق توصيل',
        branchId: 'b2',
        hireDate: now.subtract(const Duration(days: 120)),
        phone: '0912000006',
        baseSalary: 1600,
        overtime: 200,
        deductions: 40,
      ),
    ];
    payrollTxns = [
      DemoPayrollTxn(
        id: 'PT-1',
        employeeId: 'E1',
        type: DemoPayrollTxnType.advance,
        amount: 1000,
        date: now.subtract(const Duration(days: 10)),
        note: 'سلفة على الراتب',
      ),
      DemoPayrollTxn(
        id: 'PT-2',
        employeeId: 'E3',
        type: DemoPayrollTxnType.withdrawal,
        amount: 300,
        date: now.subtract(const Duration(days: 5)),
        note: 'سحب نقدي',
      ),
      DemoPayrollTxn(
        id: 'PT-3',
        employeeId: 'E4',
        type: DemoPayrollTxnType.advance,
        amount: 500,
        date: now.subtract(const Duration(days: 8)),
        note: 'سلفة طارئة',
      ),
      DemoPayrollTxn(
        id: 'PT-4',
        employeeId: 'E2',
        type: DemoPayrollTxnType.withdrawal,
        amount: 200,
        date: now.subtract(const Duration(days: 3)),
        note: 'سحب',
      ),
    ];
    terminals = const [
      DemoTerminal(
        id: 'POS-01',
        branchId: 'b1',
        name: 'الكاشير الرئيسي',
        status: 'متصل',
      ),
      DemoTerminal(
        id: 'POS-02',
        branchId: 'b1',
        name: 'الكاشير 2',
        status: 'متاح',
      ),
      DemoTerminal(
        id: 'POS-05',
        branchId: 'b2',
        name: 'نقطة بنغازي',
        status: 'متصل',
      ),
    ];
    notifications = [
      DemoNotification(
        id: 'n1',
        title: 'مخزون منخفض',
        message: 'عدة أصناف تحتاج إلى إعادة طلب.',
        date: now,
      ),
    ];
    users = const [
      DemoUser(id: 'u1', name: 'أحمد الفيتوري', role: 'مدير', active: true),
      DemoUser(id: 'u2', name: 'سالم المبروك', role: 'كاشير', active: true),
    ];
    statusHistory = [
      DemoStatusHistory(
        id: 'h1',
        entityId: 'INV-1048',
        status: 'مدفوعة',
        date: now,
        actor: 'أحمد الفيتوري',
      ),
    ];
  }

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
    // keeps its seeded accounts/movements instead of being wiped to empty.
    if (j['accounts'] != null) {
      accounts =
          (j['accounts'] as List)
              .map(
                (e) => DemoAccount.fromJson(Map<String, dynamic>.from(e as Map)),
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
                (e) =>
                    DemoLedgerAccount.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    }
    if (j['journalEntries'] != null) {
      journalEntries =
          (j['journalEntries'] as List)
              .map(
                (e) =>
                    DemoJournalEntry.fromJson(Map<String, dynamic>.from(e as Map)),
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
                (e) => DemoEmployee.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    }
    if (j['payrollTxns'] != null) {
      payrollTxns =
          (j['payrollTxns'] as List)
              .map(
                (e) =>
                    DemoPayrollTxn.fromJson(Map<String, dynamic>.from(e as Map)),
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
        'treasuryMovements':
            treasuryMovements.map((e) => e.toJson()).toList(),
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
      if (entry.value <= 0 || p.stock < entry.value)
        throw StateError('المخزون غير كافٍ للصنف ${p.name}');
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
        id: 'INV-${1049 + sales.length}',
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
        actor: 'المستخدم الحالي',
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
        reference.isEmpty ? 'TRF-${treasuryMovements.length + 1}' : reference;
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
  List<DemoJournalEntry> entriesTouching(String accountId) => journalEntries
      .where((e) =>
          _countsForBalance(e) && e.lines.any((l) => l.accountId == accountId))
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
      String action, String entryNumber, String before, String after) {
    accountingAudit = [
      DemoAccountingAudit(
        id: 'AUD-${DateTime.now().microsecondsSinceEpoch}',
        date: DateTime.now(),
        user: 'المستخدم الحالي',
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
        entry.status == DemoEntryStatus.posted ? 'مُرحّل' : 'مسودة');
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
      createdBy: 'المستخدم الحالي',
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
        .where((t) =>
            t.employeeId == employeeId &&
            t.date.year == m.year &&
            t.date.month == m.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double advancesTotal(String employeeId, {DateTime? month}) => payrollTxnsFor(
          employeeId,
          month: month)
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
  List<DemoExpense> linkedExpensesFor(String employeeId) => expenses
      .where((x) => x.employeeId == employeeId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  /// Whether the employee has a salary payment recorded in [month].
  bool isSalaryPaid(String employeeId, {DateTime? month}) {
    final m = month ?? DateTime.now();
    return expenses.any((x) =>
        x.employeeId == employeeId &&
        x.category == 'مرتبات' &&
        x.date.year == m.year &&
        x.date.month == m.month);
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
