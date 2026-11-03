/// Lightweight value for the workspace branch switcher. Its [id] is a real
/// store branch id (DemoBranch.id) — the switcher's options come from the
/// store, so there is no second branch list to keep in sync.
class AppBranch {
  const AppBranch(this.id, this.name);
  final String id;
  final String name;
}

/// Fallback used before the store's branches are read; matches the first-run
/// default branch id in `core/demo/default_data.dart`.
const kDefaultBranch = AppBranch('b1', 'الفرع الرئيسي');
