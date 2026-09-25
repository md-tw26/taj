import '../local/app_database.dart';

/// Clean interface for branch data access.
/// Screens should depend on this, not on the database directly.
abstract class BranchRepository {
  Future<List<Branch>> getAll();
  Stream<List<Branch>> watchAll();
  Future<Branch> getById(String id);
  Future<void> upsert(BranchesCompanion entry);
  Future<void> delete(String id);
}
