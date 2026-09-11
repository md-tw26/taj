/// The branches the workspace switcher (sidebar) can select between. Kept as a
/// single shared source so the selected-branch state is app-wide and new
/// branches can be added here without touching the UI.
class AppBranch {
  const AppBranch(this.id, this.name);
  final String id;
  final String name;
}

const kBranches = <AppBranch>[
  AppBranch('main', 'الفرع الرئيسي'),
  AppBranch('tripoli', 'طرابلس - المركز'),
  AppBranch('benghazi', 'بنغازي - الفرع'),
  AppBranch('misrata', 'مصراتة - السوق'),
];

const kDefaultBranch = AppBranch('main', 'الفرع الرئيسي');
