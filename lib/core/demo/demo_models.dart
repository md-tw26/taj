import 'package:flutter/material.dart';

enum DemoSaleStatus { paid, credit, returned, pending, cancelled }

enum DemoPaymentMethod { cash, bank, card, sadad, credit }

class DemoBranch {
  const DemoBranch({
    required this.id,
    required this.name,
    required this.city,
    this.active = true,
  });
  final String id;
  final String name;
  final String city;
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'active': active,
  };
  factory DemoBranch.fromJson(Map<String, dynamic> j) => DemoBranch(
    id: j['id'] as String,
    name: j['name'] as String,
    city: j['city'] as String,
    active: j['active'] as bool? ?? true,
  );
}

class DemoProduct {
  const DemoProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.reorderLevel,
    this.iconCode = 'spa',
  });
  final String id;
  final String name;
  final String barcode;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final int reorderLevel;
  final String iconCode;

  DemoProduct copyWith({
    String? name,
    String? barcode,
    String? category,
    double? price,
    double? cost,
    int? stock,
    int? reorderLevel,
    String? iconCode,
  }) => DemoProduct(
    id: id,
    name: name ?? this.name,
    barcode: barcode ?? this.barcode,
    category: category ?? this.category,
    price: price ?? this.price,
    cost: cost ?? this.cost,
    stock: stock ?? this.stock,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    iconCode: iconCode ?? this.iconCode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'category': category,
    'price': price,
    'cost': cost,
    'stock': stock,
    'reorderLevel': reorderLevel,
    'iconCode': iconCode,
  };
  factory DemoProduct.fromJson(Map<String, dynamic> j) => DemoProduct(
    id: j['id'] as String,
    name: j['name'] as String,
    barcode: j['barcode'] as String,
    category: j['category'] as String,
    price: (j['price'] as num).toDouble(),
    cost: (j['cost'] as num).toDouble(),
    stock: (j['stock'] as num).toInt(),
    reorderLevel: (j['reorderLevel'] as num?)?.toInt() ?? 5,
    iconCode: j['iconCode'] as String? ?? 'spa',
  );
}

class DemoCustomer {
  const DemoCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.creditLimit,
    this.balance = 0,
    this.active = true,
  });
  final String id;
  final String name;
  final String phone;
  final double creditLimit;
  final double balance;
  final bool active;

  DemoCustomer copyWith({
    String? name,
    String? phone,
    double? creditLimit,
    double? balance,
    bool? active,
  }) => DemoCustomer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    creditLimit: creditLimit ?? this.creditLimit,
    balance: balance ?? this.balance,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'creditLimit': creditLimit,
    'balance': balance,
    'active': active,
  };
  factory DemoCustomer.fromJson(Map<String, dynamic> j) => DemoCustomer(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    creditLimit: (j['creditLimit'] as num).toDouble(),
    balance: (j['balance'] as num?)?.toDouble() ?? 0,
    active: j['active'] as bool? ?? true,
  );
}

class DemoSupplier {
  const DemoSupplier({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0,
  });
  final String id;
  final String name;
  final String phone;
  final double balance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'balance': balance,
  };
  factory DemoSupplier.fromJson(Map<String, dynamic> j) => DemoSupplier(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String,
    balance: (j['balance'] as num?)?.toDouble() ?? 0,
  );
}

class DemoSaleLine {
  const DemoSaleLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
  final String productId;
  final int quantity;
  final double unitPrice;
  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
  factory DemoSaleLine.fromJson(Map<String, dynamic> j) => DemoSaleLine(
    productId: j['productId'] as String,
    quantity: (j['quantity'] as num).toInt(),
    unitPrice: (j['unitPrice'] as num).toDouble(),
  );
}

class DemoSale {
  const DemoSale({
    required this.id,
    required this.branchId,
    required this.date,
    required this.lines,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.customerId,
    this.note,
  });
  final String id;
  final String branchId;
  final DateTime date;
  final List<DemoSaleLine> lines;
  final double total;
  final DemoSaleStatus status;
  final DemoPaymentMethod paymentMethod;
  final String? customerId;
  final String? note;

  DemoSale copyWith({DemoSaleStatus? status}) => DemoSale(
    id: id,
    branchId: branchId,
    date: date,
    lines: lines,
    total: total,
    status: status ?? this.status,
    paymentMethod: paymentMethod,
    customerId: customerId,
    note: note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'date': date.toIso8601String(),
    'lines': lines.map((e) => e.toJson()).toList(),
    'total': total,
    'status': status.name,
    'paymentMethod': paymentMethod.name,
    'customerId': customerId,
    'note': note,
  };
  factory DemoSale.fromJson(Map<String, dynamic> j) => DemoSale(
    id: j['id'] as String,
    branchId: j['branchId'] as String,
    date: DateTime.parse(j['date'] as String),
    lines:
        (j['lines'] as List)
            .map(
              (e) => DemoSaleLine.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
    total: (j['total'] as num).toDouble(),
    status: DemoSaleStatus.values.byName(j['status'] as String),
    paymentMethod: DemoPaymentMethod.values.byName(
      j['paymentMethod'] as String,
    ),
    customerId: j['customerId'] as String?,
    note: j['note'] as String?,
  );
}

class DemoPurchase {
  const DemoPurchase({
    required this.id,
    required this.supplierId,
    required this.date,
    required this.total,
    required this.paid,
  });
  final String id;
  final String supplierId;
  final DateTime date;
  final double total;
  final bool paid;
  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierId': supplierId,
    'date': date.toIso8601String(),
    'total': total,
    'paid': paid,
  };
  factory DemoPurchase.fromJson(Map<String, dynamic> j) => DemoPurchase(
    id: j['id'] as String,
    supplierId: j['supplierId'] as String,
    date: DateTime.parse(j['date'] as String),
    total: (j['total'] as num).toDouble(),
    paid: j['paid'] as bool,
  );
}

class DemoExpense {
  const DemoExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.branchId,
    required this.method,
    this.employeeId,
  });
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String branchId;
  final DemoPaymentMethod method;

  /// For the "مرتبات" (salaries) category: the employee this expense pays,
  /// linking it to the payroll profile.
  final String? employeeId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'branchId': branchId,
    'method': method.name,
    'employeeId': employeeId,
  };
  factory DemoExpense.fromJson(Map<String, dynamic> j) => DemoExpense(
    id: j['id'] as String,
    category: j['category'] as String,
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    branchId: j['branchId'] as String,
    method: DemoPaymentMethod.values.byName(j['method'] as String),
    employeeId: j['employeeId'] as String?,
  );
}

class DemoTerminal {
  const DemoTerminal({
    required this.id,
    required this.branchId,
    required this.name,
    required this.status,
  });
  final String id;
  final String branchId;
  final String name;
  final String status;
  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': branchId,
    'name': name,
    'status': status,
  };
  factory DemoTerminal.fromJson(Map<String, dynamic> j) => DemoTerminal(
    id: j['id'] as String,
    branchId: j['branchId'] as String,
    name: j['name'] as String,
    status: j['status'] as String,
  );
}

class DemoNotification {
  const DemoNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.read = false,
  });
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool read;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'date': date.toIso8601String(),
    'read': read,
  };
  factory DemoNotification.fromJson(Map<String, dynamic> j) => DemoNotification(
    id: j['id'] as String,
    title: j['title'] as String,
    message: j['message'] as String,
    date: DateTime.parse(j['date'] as String),
    read: j['read'] as bool? ?? false,
  );
}

class DemoUser {
  const DemoUser({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
  });
  final String id;
  final String name;
  final String role;
  final bool active;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'active': active,
  };
  factory DemoUser.fromJson(Map<String, dynamic> j) => DemoUser(
    id: j['id'] as String,
    name: j['name'] as String,
    role: j['role'] as String,
    active: j['active'] as bool? ?? true,
  );
}

class DemoStatusHistory {
  const DemoStatusHistory({
    required this.id,
    required this.entityId,
    required this.status,
    required this.date,
    required this.actor,
  });
  final String id;
  final String entityId;
  final String status;
  final DateTime date;
  final String actor;
  Map<String, dynamic> toJson() => {
    'id': id,
    'entityId': entityId,
    'status': status,
    'date': date.toIso8601String(),
    'actor': actor,
  };
  factory DemoStatusHistory.fromJson(Map<String, dynamic> j) =>
      DemoStatusHistory(
        id: j['id'] as String,
        entityId: j['entityId'] as String,
        status: j['status'] as String,
        date: DateTime.parse(j['date'] as String),
        actor: j['actor'] as String,
      );
}

/// A treasury account — a physical cash box or a bank account.
enum DemoAccountType { cash, bank }

/// A cash box or bank account held by the business. Its live balance is its
/// [openingBalance] plus the signed sum of its treasury movements; it is never
/// stored denormalised so a movement can never disagree with the balance.
class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.branchId,
    this.openingBalance = 0,
    this.bankName,
    this.accountNo,
  });
  final String id;
  final String name;
  final DemoAccountType type;
  final String branchId;
  final double openingBalance;

  /// Bank-account metadata (null for cash boxes).
  final String? bankName;
  final String? accountNo;

  DemoAccount copyWith({
    String? name,
    DemoAccountType? type,
    String? branchId,
    double? openingBalance,
    String? bankName,
    String? accountNo,
  }) => DemoAccount(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    branchId: branchId ?? this.branchId,
    openingBalance: openingBalance ?? this.openingBalance,
    bankName: bankName ?? this.bankName,
    accountNo: accountNo ?? this.accountNo,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'branchId': branchId,
    'openingBalance': openingBalance,
    'bankName': bankName,
    'accountNo': accountNo,
  };
  factory DemoAccount.fromJson(Map<String, dynamic> j) => DemoAccount(
    id: j['id'] as String,
    name: j['name'] as String,
    type: DemoAccountType.values.byName(j['type'] as String),
    branchId: j['branchId'] as String,
    openingBalance: (j['openingBalance'] as num?)?.toDouble() ?? 0,
    bankName: j['bankName'] as String?,
    accountNo: j['accountNo'] as String?,
  );
}

/// The kind of treasury movement. A [transfer] is recorded as two paired
/// movements (one outflow on the source account, one inflow on the
/// destination), each pointing at the other via [DemoTreasuryMovement
/// .counterAccountId]. A [reconcile] records the adjustment that aligns the
/// book balance with a bank statement.
enum DemoMovementType { deposit, withdraw, transfer, reconcile }

/// A single line in an account's daily movement log. [amount] is always stored
/// non-negative; [isInflow] carries the direction so the in/out columns and the
/// running balance are unambiguous regardless of type.
class DemoTreasuryMovement {
  const DemoTreasuryMovement({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    required this.isInflow,
    this.reference = '',
    this.description = '',
    this.counterAccountId,
    this.reconciled = true,
  });
  final String id;
  final String accountId;
  final DemoMovementType type;
  final double amount;
  final DateTime date;

  /// True when the movement increases the account balance (deposit / incoming
  /// transfer / positive reconcile), false when it decreases it.
  final bool isInflow;
  final String reference;
  final String description;

  /// For transfers: the account on the other side of the movement.
  final String? counterAccountId;

  /// Whether this movement has cleared the bank statement. The book balance
  /// counts every movement; the statement balance counts only reconciled ones,
  /// so their difference is exactly the sum of the un-reconciled movements.
  final bool reconciled;

  /// The balance delta this movement applies (+ for inflow, − for outflow).
  double get signedAmount => isInflow ? amount : -amount;

  DemoTreasuryMovement copyWith({bool? reconciled}) => DemoTreasuryMovement(
    id: id,
    accountId: accountId,
    type: type,
    amount: amount,
    date: date,
    isInflow: isInflow,
    reference: reference,
    description: description,
    counterAccountId: counterAccountId,
    reconciled: reconciled ?? this.reconciled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'isInflow': isInflow,
    'reference': reference,
    'description': description,
    'counterAccountId': counterAccountId,
    'reconciled': reconciled,
  };
  factory DemoTreasuryMovement.fromJson(Map<String, dynamic> j) =>
      DemoTreasuryMovement(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        type: DemoMovementType.values.byName(j['type'] as String),
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        isInflow: j['isInflow'] as bool,
        reference: j['reference'] as String? ?? '',
        description: j['description'] as String? ?? '',
        counterAccountId: j['counterAccountId'] as String?,
        reconciled: j['reconciled'] as bool? ?? true,
      );
}

// ---------------------------------------------------------------------------
// Accounting (double-entry): chart of accounts, journal entries, audit log
// ---------------------------------------------------------------------------

/// Chart-of-accounts classification. Assets & expenses are debit-normal;
/// liabilities, equity & revenue are credit-normal.
enum DemoLedgerAccountType { asset, liability, equity, revenue, expense }

extension DemoLedgerAccountTypeX on DemoLedgerAccountType {
  /// Debit-normal accounts increase with debits (assets, expenses).
  bool get isDebitNormal =>
      this == DemoLedgerAccountType.asset ||
      this == DemoLedgerAccountType.expense;
}

/// A node in the chart of accounts. The tree is derived from [parentId]; [code]
/// is the hierarchical account number (e.g. "1", "11", "1101"). A node with
/// children is a header/group; only leaf nodes are posted to.
class DemoLedgerAccount {
  const DemoLedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.openingBalance = 0,
  });
  final String id;
  final String code;
  final String name;
  final DemoLedgerAccountType type;
  final String? parentId;
  final double openingBalance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type.name,
    'parentId': parentId,
    'openingBalance': openingBalance,
  };
  factory DemoLedgerAccount.fromJson(Map<String, dynamic> j) =>
      DemoLedgerAccount(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        type: DemoLedgerAccountType.values.byName(j['type'] as String),
        parentId: j['parentId'] as String?,
        openingBalance: (j['openingBalance'] as num?)?.toDouble() ?? 0,
      );
}

/// One debit/credit line of a journal entry. Exactly one of [debit]/[credit] is
/// non-zero in normal use; both are stored so no raw figure is ever lost.
class DemoJournalLine {
  const DemoJournalLine({
    required this.accountId,
    this.debit = 0,
    this.credit = 0,
    this.description = '',
  });
  final String accountId;
  final double debit;
  final double credit;
  final String description;

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'debit': debit,
    'credit': credit,
    'description': description,
  };
  factory DemoJournalLine.fromJson(Map<String, dynamic> j) => DemoJournalLine(
    accountId: j['accountId'] as String,
    debit: (j['debit'] as num?)?.toDouble() ?? 0,
    credit: (j['credit'] as num?)?.toDouble() ?? 0,
    description: j['description'] as String? ?? '',
  );
}

/// Posting/lifecycle status of a journal entry.
enum DemoEntryStatus { draft, posted, reversed }

/// A journal (voucher) entry: a balanced set of debit/credit lines with a
/// plain-Arabic explanation, a lifecycle status, review/approval flags,
/// optional attachments, and a link back to the entry it reverses.
class DemoJournalEntry {
  const DemoJournalEntry({
    required this.id,
    required this.number,
    required this.date,
    required this.description,
    required this.lines,
    this.status = DemoEntryStatus.draft,
    this.reviewed = false,
    this.approved = false,
    this.branchId = 'b1',
    this.reference = '',
    this.attachments = const [],
    this.reversalOfId,
    this.createdBy = '',
  });
  final String id;
  final String number;
  final DateTime date;
  final String description;
  final List<DemoJournalLine> lines;
  final DemoEntryStatus status;
  final bool reviewed;
  final bool approved;
  final String branchId;
  final String reference;
  final List<String> attachments;
  final String? reversalOfId;
  final String createdBy;

  double get totalDebit => lines.fold(0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold(0, (s, l) => s + l.credit);
  double get difference => totalDebit - totalCredit;
  bool get isBalanced => difference.abs() < 0.005;

  DemoJournalEntry copyWith({
    DemoEntryStatus? status,
    bool? reviewed,
    bool? approved,
  }) => DemoJournalEntry(
    id: id,
    number: number,
    date: date,
    description: description,
    lines: lines,
    status: status ?? this.status,
    reviewed: reviewed ?? this.reviewed,
    approved: approved ?? this.approved,
    branchId: branchId,
    reference: reference,
    attachments: attachments,
    reversalOfId: reversalOfId,
    createdBy: createdBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'date': date.toIso8601String(),
    'description': description,
    'lines': lines.map((l) => l.toJson()).toList(),
    'status': status.name,
    'reviewed': reviewed,
    'approved': approved,
    'branchId': branchId,
    'reference': reference,
    'attachments': attachments,
    'reversalOfId': reversalOfId,
    'createdBy': createdBy,
  };
  factory DemoJournalEntry.fromJson(Map<String, dynamic> j) => DemoJournalEntry(
    id: j['id'] as String,
    number: j['number'] as String,
    date: DateTime.parse(j['date'] as String),
    description: j['description'] as String? ?? '',
    lines: (j['lines'] as List)
        .map((e) => DemoJournalLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    status: DemoEntryStatus.values.byName(j['status'] as String? ?? 'draft'),
    reviewed: j['reviewed'] as bool? ?? false,
    approved: j['approved'] as bool? ?? false,
    branchId: j['branchId'] as String? ?? 'b1',
    reference: j['reference'] as String? ?? '',
    attachments:
        (j['attachments'] as List?)?.map((e) => e as String).toList() ?? const [],
    reversalOfId: j['reversalOfId'] as String?,
    createdBy: j['createdBy'] as String? ?? '',
  );
}

/// One line in the accounting audit log (who did what, when, and the before/
/// after snapshot — either side can be long).
class DemoAccountingAudit {
  const DemoAccountingAudit({
    required this.id,
    required this.date,
    required this.user,
    required this.action,
    required this.entryNumber,
    this.before = '',
    this.after = '',
  });
  final String id;
  final DateTime date;
  final String user;
  final String action;
  final String entryNumber;
  final String before;
  final String after;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'user': user,
    'action': action,
    'entryNumber': entryNumber,
    'before': before,
    'after': after,
  };
  factory DemoAccountingAudit.fromJson(Map<String, dynamic> j) =>
      DemoAccountingAudit(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        user: j['user'] as String,
        action: j['action'] as String,
        entryNumber: j['entryNumber'] as String,
        before: j['before'] as String? ?? '',
        after: j['after'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Employees & Payroll
// ---------------------------------------------------------------------------

/// An employee with the monthly salary components. Advances and withdrawals are
/// separate dated transactions ([DemoPayrollTxn]); the net is computed, never
/// stored, so it can never disagree with its parts.
class DemoEmployee {
  const DemoEmployee({
    required this.id,
    required this.name,
    required this.title,
    required this.branchId,
    required this.hireDate,
    this.phone = '',
    this.active = true,
    this.baseSalary = 0,
    this.allowances = 0,
    this.bonuses = 0,
    this.commissions = 0,
    this.overtime = 0,
    this.deductions = 0,
  });
  final String id;
  final String name;
  final String title;
  final String branchId;
  final DateTime hireDate;
  final String phone;
  final bool active;
  final double baseSalary;
  final double allowances;
  final double bonuses;
  final double commissions;
  final double overtime;
  final double deductions;

  /// Earnings before any deduction.
  double get grossEarnings =>
      baseSalary + allowances + bonuses + commissions + overtime;

  /// First character of the name, for an avatar fallback.
  String get initial =>
      name.trim().isEmpty ? '؟' : name.trim().substring(0, 1);

  DemoEmployee copyWith({
    String? name,
    String? title,
    String? branchId,
    DateTime? hireDate,
    String? phone,
    bool? active,
    double? baseSalary,
    double? allowances,
    double? bonuses,
    double? commissions,
    double? overtime,
    double? deductions,
  }) => DemoEmployee(
    id: id,
    name: name ?? this.name,
    title: title ?? this.title,
    branchId: branchId ?? this.branchId,
    hireDate: hireDate ?? this.hireDate,
    phone: phone ?? this.phone,
    active: active ?? this.active,
    baseSalary: baseSalary ?? this.baseSalary,
    allowances: allowances ?? this.allowances,
    bonuses: bonuses ?? this.bonuses,
    commissions: commissions ?? this.commissions,
    overtime: overtime ?? this.overtime,
    deductions: deductions ?? this.deductions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'branchId': branchId,
    'hireDate': hireDate.toIso8601String(),
    'phone': phone,
    'active': active,
    'baseSalary': baseSalary,
    'allowances': allowances,
    'bonuses': bonuses,
    'commissions': commissions,
    'overtime': overtime,
    'deductions': deductions,
  };
  factory DemoEmployee.fromJson(Map<String, dynamic> j) => DemoEmployee(
    id: j['id'] as String,
    name: j['name'] as String,
    title: j['title'] as String? ?? '',
    branchId: j['branchId'] as String? ?? 'b1',
    hireDate: DateTime.parse(j['hireDate'] as String),
    phone: j['phone'] as String? ?? '',
    active: j['active'] as bool? ?? true,
    baseSalary: (j['baseSalary'] as num?)?.toDouble() ?? 0,
    allowances: (j['allowances'] as num?)?.toDouble() ?? 0,
    bonuses: (j['bonuses'] as num?)?.toDouble() ?? 0,
    commissions: (j['commissions'] as num?)?.toDouble() ?? 0,
    overtime: (j['overtime'] as num?)?.toDouble() ?? 0,
    deductions: (j['deductions'] as num?)?.toDouble() ?? 0,
  );
}

/// A one-off payroll transaction against an employee: an advance (loan against
/// salary) or a withdrawal. Both reduce net pay for the period.
enum DemoPayrollTxnType { advance, withdrawal }

class DemoPayrollTxn {
  const DemoPayrollTxn({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });
  final String id;
  final String employeeId;
  final DemoPayrollTxnType type;
  final double amount;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };
  factory DemoPayrollTxn.fromJson(Map<String, dynamic> j) => DemoPayrollTxn(
    id: j['id'] as String,
    employeeId: j['employeeId'] as String,
    type: DemoPayrollTxnType.values.byName(j['type'] as String),
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
  );
}

IconData demoIcon(String code) {
  switch (code) {
    case 'local_florist':
      return Icons.local_florist_outlined;
    case 'fire':
      return Icons.local_fire_department_outlined;
    case 'water':
      return Icons.water_drop_outlined;
    case 'oil':
      return Icons.opacity_outlined;
    case 'gift':
      return Icons.card_giftcard_outlined;
    default:
      return Icons.spa_outlined;
  }
}
