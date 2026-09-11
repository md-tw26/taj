import 'package:flutter/foundation.dart';

/// Roles available in TAJ.
enum UserRole { admin, merchant, cashier }

/// Permission flag set derived from a user's role.
///
/// Only the permissions that actually gate UI behaviour are enumerated here;
/// add more as needed (e.g. `sales.refund`, `inventory.adjust`).
@immutable
class UserPermissions {
  const UserPermissions({
    required this.changePrice,
    required this.applyDiscounts,
    required this.refund,
    required this.viewReports,
  });

  final bool changePrice;
  final bool applyDiscounts;
  final bool refund;
  final bool viewReports;

  /// Build the canonical permission set for a given role.
  factory UserPermissions.forRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.merchant:
        return const UserPermissions(
          changePrice: true,
          applyDiscounts: true,
          refund: true,
          viewReports: true,
        );
      case UserRole.cashier:
        return const UserPermissions(
          changePrice: false,
          applyDiscounts: false,
          refund: false,
          viewReports: false,
        );
    }
  }

  static const UserPermissions admin = UserPermissions(
    changePrice: true,
    applyDiscounts: true,
    refund: true,
    viewReports: true,
  );
  static const UserPermissions merchant = UserPermissions(
    changePrice: true,
    applyDiscounts: true,
    refund: true,
    viewReports: true,
  );
  static const UserPermissions cashier = UserPermissions(
    changePrice: false,
    applyDiscounts: false,
    refund: false,
    viewReports: false,
  );
}

