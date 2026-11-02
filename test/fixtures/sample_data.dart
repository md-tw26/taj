// Sample business data for tests.
//
// This is the exact dataset that used to live in `DemoStore._seed()` before
// the demo-data removal pass (see `TAJ-Remove-Demo-Data-Prompt.md`): fake
// branches, products, customers, sales, treasury accounts, a chart of
// accounts (including a deliberately deep branch and a long Arabic name to
// stress tree indentation and text wrapping), journal entries, employees,
// POS terminals and more. Production code must never import this file — it
// exists purely so widget/responsive tests keep rendering a populated UI
// without each test re-inventing its own fixtures.
//
// Dates stay relative to [DateTime.now()] (as the original seed did), so a
// test run always sees "yesterday", "last month", etc. rather than a frozen
// calendar date.

import 'package:taj/core/demo/demo_models.dart';
import 'package:taj/core/demo/demo_store.dart';

/// Builds a [DemoStore] that doesn't touch SharedPreferences, pre-filled with
/// the sample dataset below. Each call returns a fresh, independent store.
DemoStore buildSampleStore() {
  final store = DemoStore(autoLoad: false, enablePersistence: false);
  applySampleData(store);
  return store;
}

/// Fills [store]'s public collections with the sample dataset. Useful when a
/// test already has a store instance (e.g. one built with [DemoStore.new])
/// and wants to seed it explicitly rather than rely on a fresh one.
void applySampleData(DemoStore store) {
  final now = DateTime.now();

  store.branches = const [
    DemoBranch(id: 'b1', name: 'طرابلس - الفرع الرئيسي', city: 'طرابلس'),
    DemoBranch(id: 'b2', name: 'بنغازي - الفرع الشرقي', city: 'بنغازي'),
    DemoBranch(id: 'b3', name: 'مصراتة - السوق', city: 'مصراتة'),
    DemoBranch(id: 'b4', name: 'الزاوية - الفرع الغربي', city: 'الزاوية'),
  ];

  store.products = const [
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

  store.customers = const [
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

  store.suppliers = const [
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

  store.sales = [
    DemoSale(
      id: 'INV-1048',
      branchId: 'b1',
      date: now.subtract(const Duration(days: 1)),
      lines: const [DemoSaleLine(productId: 'p1', quantity: 1, unitPrice: 450)],
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

  store.purchases = [
    DemoPurchase(
      id: 'PUR-210',
      supplierId: 's1',
      date: now.subtract(const Duration(days: 4)),
      total: 5400,
      paid: false,
    ),
  ];

  store.expenses = [
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

  store.accounts = const [
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

  store.treasuryMovements = [
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

  store.ledgerAccounts = const [
    // 1 Assets
    DemoLedgerAccount(
      id: '1',
      code: '1',
      name: 'الأصول',
      type: DemoLedgerAccountType.asset,
    ),
    DemoLedgerAccount(
      id: '11',
      code: '11',
      name: 'الأصول المتداولة',
      type: DemoLedgerAccountType.asset,
      parentId: '1',
    ),
    DemoLedgerAccount(
      id: '1101',
      code: '1101',
      name: 'الصندوق',
      type: DemoLedgerAccountType.asset,
      parentId: '11',
    ),
    DemoLedgerAccount(
      id: '1102',
      code: '1102',
      name: 'المصارف',
      type: DemoLedgerAccountType.asset,
      parentId: '11',
    ),
    // Two specific banks, plus a long-named deep branch below — kept here
    // (not shipped in the app's production defaults) purely to stress-test
    // the chart-of-accounts tree UI: text wrapping at depth and indentation.
    DemoLedgerAccount(
      id: '110201',
      code: '110201',
      name: 'مصرف الجمهورية',
      type: DemoLedgerAccountType.asset,
      parentId: '1102',
    ),
    DemoLedgerAccount(
      id: '110202',
      code: '110202',
      name: 'مصرف التجارة والتنمية',
      type: DemoLedgerAccountType.asset,
      parentId: '1102',
    ),
    DemoLedgerAccount(
      id: '1103',
      code: '1103',
      name: 'ذمم العملاء',
      type: DemoLedgerAccountType.asset,
      parentId: '11',
    ),
    DemoLedgerAccount(
      id: '1104',
      code: '1104',
      name: 'المخزون',
      type: DemoLedgerAccountType.asset,
      parentId: '11',
    ),
    // 12 Fixed assets
    DemoLedgerAccount(
      id: '12',
      code: '12',
      name: 'الأصول الثابتة',
      type: DemoLedgerAccountType.asset,
      parentId: '1',
    ),
    DemoLedgerAccount(
      id: '1201',
      code: '1201',
      name: 'الأثاث والمعدات',
      type: DemoLedgerAccountType.asset,
      parentId: '12',
    ),
    // Deep branch (depth 6) to stress tree indentation + long names.
    DemoLedgerAccount(
      id: '1203',
      code: '1203',
      name: 'أصول أخرى',
      type: DemoLedgerAccountType.asset,
      parentId: '12',
    ),
    DemoLedgerAccount(
      id: '120301',
      code: '120301',
      name: 'المستوى الثالث',
      type: DemoLedgerAccountType.asset,
      parentId: '1203',
    ),
    DemoLedgerAccount(
      id: '12030101',
      code: '12030101',
      name: 'المستوى الرابع',
      type: DemoLedgerAccountType.asset,
      parentId: '120301',
    ),
    DemoLedgerAccount(
      id: '1203010101',
      code: '1203010101',
      name: 'المستوى الخامس',
      type: DemoLedgerAccountType.asset,
      parentId: '12030101',
    ),
    DemoLedgerAccount(
      id: '120301010101',
      code: '120301010101',
      name: 'المستوى السادس - حساب بأسم عربي طويل جدًا لاختبار التداخل',
      type: DemoLedgerAccountType.asset,
      parentId: '1203010101',
    ),
    // 2 Liabilities
    DemoLedgerAccount(
      id: '2',
      code: '2',
      name: 'الخصوم',
      type: DemoLedgerAccountType.liability,
    ),
    DemoLedgerAccount(
      id: '21',
      code: '21',
      name: 'الخصوم المتداولة',
      type: DemoLedgerAccountType.liability,
      parentId: '2',
    ),
    DemoLedgerAccount(
      id: '2101',
      code: '2101',
      name: 'ذمم الموردين',
      type: DemoLedgerAccountType.liability,
      parentId: '21',
    ),
    DemoLedgerAccount(
      id: '2102',
      code: '2102',
      name: 'مصلحة الضرائب',
      type: DemoLedgerAccountType.liability,
      parentId: '21',
    ),
    // 3 Equity
    DemoLedgerAccount(
      id: '3',
      code: '3',
      name: 'حقوق الملكية',
      type: DemoLedgerAccountType.equity,
    ),
    DemoLedgerAccount(
      id: '3101',
      code: '3101',
      name: 'رأس المال',
      type: DemoLedgerAccountType.equity,
      parentId: '3',
    ),
    DemoLedgerAccount(
      id: '3102',
      code: '3102',
      name: 'الأرباح المحتجزة',
      type: DemoLedgerAccountType.equity,
      parentId: '3',
    ),
    // 4 Revenue
    DemoLedgerAccount(
      id: '4',
      code: '4',
      name: 'الإيرادات',
      type: DemoLedgerAccountType.revenue,
    ),
    DemoLedgerAccount(
      id: '4101',
      code: '4101',
      name: 'إيرادات المبيعات',
      type: DemoLedgerAccountType.revenue,
      parentId: '4',
    ),
    DemoLedgerAccount(
      id: '4102',
      code: '4102',
      name: 'إيرادات أخرى',
      type: DemoLedgerAccountType.revenue,
      parentId: '4',
    ),
    // 5 Expenses
    DemoLedgerAccount(
      id: '5',
      code: '5',
      name: 'المصروفات',
      type: DemoLedgerAccountType.expense,
    ),
    DemoLedgerAccount(
      id: '5101',
      code: '5101',
      name: 'تكلفة المبيعات',
      type: DemoLedgerAccountType.expense,
      parentId: '5',
    ),
    DemoLedgerAccount(
      id: '5102',
      code: '5102',
      name: 'الرواتب والأجور',
      type: DemoLedgerAccountType.expense,
      parentId: '5',
    ),
    DemoLedgerAccount(
      id: '5103',
      code: '5103',
      name: 'الإيجار',
      type: DemoLedgerAccountType.expense,
      parentId: '5',
    ),
    DemoLedgerAccount(
      id: '5104',
      code: '5104',
      name: 'الكهرباء والماء',
      type: DemoLedgerAccountType.expense,
      parentId: '5',
    ),
    DemoLedgerAccount(
      id: '5105',
      code: '5105',
      name: 'مصروفات أخرى',
      type: DemoLedgerAccountType.expense,
      parentId: '5',
    ),
  ];

  store.journalEntries = [
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
        DemoJournalLine(
          accountId: '1101',
          debit: 100000,
          description: 'إيداع رأس المال',
        ),
        DemoJournalLine(
          accountId: '3101',
          credit: 100000,
          description: 'رأس المال المدفوع',
        ),
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
        DemoJournalLine(
          accountId: '1101',
          debit: 45000,
          description: 'تحصيل نقدي',
        ),
        DemoJournalLine(
          accountId: '4101',
          credit: 45000,
          description: 'مبيعات',
        ),
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
        DemoJournalLine(
          accountId: '1201',
          debit: 22000,
          description: 'أثاث مكتبي',
        ),
        DemoJournalLine(
          accountId: '110201',
          credit: 22000,
          description: 'شيك مصرفي',
        ),
      ],
    ),
    DemoJournalEntry(
      id: 'JV-004',
      number: 'JV-004',
      date: now.subtract(const Duration(days: 20)),
      description:
          'إثبات المصروفات التشغيلية لشهر يوليو (رواتب وإيجار وكهرباء)',
      status: DemoEntryStatus.posted,
      approved: true,
      createdBy: 'سميرة',
      reference: 'EXP-JUL',
      lines: const [
        DemoJournalLine(
          accountId: '5102',
          debit: 18000,
          description: 'رواتب الموظفين',
        ),
        DemoJournalLine(
          accountId: '5103',
          debit: 6000,
          description: 'إيجار المحل',
        ),
        DemoJournalLine(
          accountId: '5104',
          debit: 1500,
          description: 'كهرباء وماء',
        ),
        DemoJournalLine(
          accountId: '110201',
          credit: 25500,
          description: 'سداد من المصرف',
        ),
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
        DemoJournalLine(
          accountId: '5105',
          debit: 3000,
          description: 'مصروف نثري',
        ),
        DemoJournalLine(
          accountId: '1101',
          credit: 2500,
          description: 'صرف نقدي',
        ),
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
        DemoJournalLine(
          accountId: '5105',
          debit: 1200,
          description: 'مصروف مكرر',
        ),
        DemoJournalLine(
          accountId: '1101',
          credit: 1200,
          description: 'صرف نقدي',
        ),
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
        DemoJournalLine(
          accountId: '1101',
          debit: 1200,
          description: 'إعادة المبلغ',
        ),
        DemoJournalLine(
          accountId: '5105',
          credit: 1200,
          description: 'إلغاء المصروف',
        ),
      ],
    ),
  ];

  store.accountingAudit = [
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

  // Employee E4's name and the "حساب بأسم عربي طويل جدًا" ledger account above
  // are deliberately long — they stress-test Arabic text wrapping/truncation.
  store.employees = [
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

  store.payrollTxns = [
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

  // Only 3 terminals here (store-level). `pos_management_test.dart` exercises
  // a much richer 11-terminal dataset with per-terminal shift/cashier data
  // that has no home in `DemoTerminal` yet (id/branch/name/status only) — that
  // dataset stays local to the screen until Phase 4 decides how much of it the
  // store can actually back with real fields.
  store.terminals = const [
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

  DateTime ago({int d = 0, int h = 0, int m = 0}) =>
      now.subtract(Duration(days: d, hours: h, minutes: m));
  store.notifications = [
    DemoNotification(
      id: 'n1',
      type: 'inventory',
      priority: 'high',
      title: 'مخزون منخفض: عود ملكي',
      message:
          'صنف «عود ملكي» وصل إلى 3 وحدات في فرع طرابلس الرئيسي، أقل من حد إعادة الطلب (5). يُنصح بإصدار أمر شراء.',
      date: ago(m: 3),
    ),
    DemoNotification(
      id: 'n2',
      type: 'approval',
      priority: 'high',
      title: 'طلب خصم بانتظار الموافقة',
      message:
          'طلب الكاشير نادية عبد السلام خصمًا يدويًا بنسبة 15% على الفاتورة #ش٢٣٠ ويتجاوز حدّ صلاحيتها.',
      date: ago(m: 21),
    ),
    DemoNotification(
      id: 'n3',
      type: 'sales',
      priority: 'normal',
      title: 'تم إغلاق وردية الصباح',
      message: 'أُغلقت وردية الصباح في فرع بنغازي بإجمالي مبيعات 4,820 د.ل.',
      date: ago(h: 2),
    ),
    DemoNotification(
      id: 'n4',
      type: 'finance',
      priority: 'normal',
      title: 'قيد محاسبي بانتظار الترحيل',
      message: 'قيد مصروفات الإيجار لشهر سبتمبر في حالة مسودة ولم يُرحَّل بعد.',
      date: ago(h: 5),
    ),
    DemoNotification(
      id: 'n5',
      type: 'system',
      priority: 'normal',
      title: 'اكتملت المزامنة',
      message: 'تمت مزامنة بيانات الفروع الثلاثة بنجاح.',
      date: ago(h: 8),
      read: true,
    ),
    DemoNotification(
      id: 'n6',
      type: 'sales',
      priority: 'normal',
      title: 'فاتورة آجلة مستحقة',
      message:
          'فاتورة العميل محمد الترهوني #ش١٩٨ بقيمة 1,250 د.ل تستحق السداد خلال يومين.',
      date: ago(d: 1, h: 1),
    ),
    DemoNotification(
      id: 'n7',
      type: 'inventory',
      priority: 'normal',
      title: 'انتهت تسوية الجرد',
      message: 'اعتُمدت تسوية جرد مستودع مصراتة مع فروقات طفيفة بقيمة 70 د.ل.',
      date: ago(d: 1, h: 4),
      read: true,
    ),
    DemoNotification(
      id: 'n8',
      type: 'approval',
      priority: 'normal',
      title: 'طلب استرداد مرتجع',
      message: 'طلب مرتجع لصنفين على الفاتورة #ش١٧٧ بانتظار موافقة المشرف.',
      date: ago(d: 2, h: 3),
    ),
  ];

  store.users = const [
    DemoUser(id: 'u1', name: 'أحمد الفيتوري', role: 'مدير', active: true),
    DemoUser(id: 'u2', name: 'سالم المبروك', role: 'كاشير', active: true),
  ];

  store.statusHistory = [
    DemoStatusHistory(
      id: 'h1',
      entityId: 'INV-1048',
      status: 'مدفوعة',
      date: now,
      actor: 'أحمد الفيتوري',
    ),
  ];
}
