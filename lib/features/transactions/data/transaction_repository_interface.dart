import '../application/quick_entry_form_provider.dart';

/// TransactionRepository의 추상 인터페이스.
///
/// 위젯·Provider에서 이 타입을 참조하면 테스트 시
/// [MockTransactionRepository] 등으로 교체할 수 있다.
abstract interface class ITransactionRepository {
  Future<void> createFromQuickEntry(QuickEntryFormState form);
  Future<void> updateFromQuickEntry(QuickEntryFormState form);
  Future<void> softDeleteTransaction(String localId);
  Future<void> undoDeleteTransaction(String localId);
}
