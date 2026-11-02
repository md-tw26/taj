import 'demo_models.dart';
import 'demo_store.dart';

/// First-run defaults for a clean install.
///
/// This is the ONLY business data the app ships with. It holds two kinds of
/// value only (see `TAJ-Remove-Demo-Data-Prompt.md` §3):
///
///  * **Reference** data the system needs to function: the general chart of
///    accounts (a standard Libyan small-business COA skeleton).
///  * **Minimal operational** data without which core flows can't start and
///    for which there is no creation screen yet: a single branch and a single
///    zero-balance cash box.
///
/// Everything else (products, customers, sales, employees, journals, …) starts
/// empty — the user fills it. No fake people, invoices, balances or history.
void applyDefaultData(DemoStore store) {
  store.branches = kDefaultBranches;
  store.accounts = kDefaultAccounts;
  store.ledgerAccounts = kDefaultLedgerAccounts;
}

/// One operational branch. Generic name — the real branch-management screen is
/// out of scope, so this is the baseline every flow (sales, treasury, …) binds
/// to until the user renames or adds branches.
const List<DemoBranch> kDefaultBranches = [
  DemoBranch(id: 'b1', name: 'الفرع الرئيسي', city: ''),
];

/// One zero-balance cash box so the cashier/treasury flows have somewhere to
/// post to on a fresh install.
const List<DemoAccount> kDefaultAccounts = [
  DemoAccount(
    id: 'ACC-C1',
    name: 'الصندوق الرئيسي',
    type: DemoAccountType.cash,
    branchId: 'b1',
    openingBalance: 0,
  ),
];

/// Standard general chart of accounts (assets / liabilities / equity / revenue
/// / expenses). Reference data — a starting skeleton, not business records.
const List<DemoLedgerAccount> kDefaultLedgerAccounts = [
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
  DemoLedgerAccount(
    id: '1203',
    code: '1203',
    name: 'أصول أخرى',
    type: DemoLedgerAccountType.asset,
    parentId: '12',
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
