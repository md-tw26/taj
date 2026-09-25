import '../local/app_database.dart';
import 'branch_repository.dart';

class DriftBranchRepository implements BranchRepository {
  DriftBranchRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Branch>> getAll() => _db.allBranches();

  @override
  Stream<List<Branch>> watchAll() => _db.watchAllBranches();

  @override
  Future<Branch> getById(String id) => _db.branchById(id);

  @override
  Future<void> upsert(BranchesCompanion entry) =>
      _db.insertBranch(entry).then((_) {});

  @override
  Future<void> delete(String id) => _db.deleteBranch(id);
}
