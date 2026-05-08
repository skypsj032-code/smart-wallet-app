import 'package:smart_wallet/features/transactions/application/quick_entry_form_provider.dart';
import 'package:smart_wallet/features/transactions/data/transaction_repository_interface.dart';

/// 테스트용 TransactionRepository mock.
///
/// 사용 예:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     transactionRepositoryProvider.overrideWithValue(MockTransactionRepository()),
///   ],
/// );
/// ```
class MockTransactionRepository implements ITransactionRepository {
  final List<QuickEntryFormState> created = [];
  final List<QuickEntryFormState> updated = [];
  final List<String> softDeleted = [];
  final List<String> undoDeleted = [];

  /// 테스트에서 강제로 예외를 던지고 싶을 때 세팅
  Exception? createError;
  Exception? updateError;

  @override
  Future<void> createFromQuickEntry(QuickEntryFormState form) async {
    if (createError != null) throw createError!;
    created.add(form);
  }

  @override
  Future<void> updateFromQuickEntry(QuickEntryFormState form) async {
    if (updateError != null) throw updateError!;
    updated.add(form);
  }

  @override
  Future<void> softDeleteTransaction(String localId) async {
    softDeleted.add(localId);
  }

  @override
  Future<void> undoDeleteTransaction(String localId) async {
    undoDeleted.add(localId);
  }
}
