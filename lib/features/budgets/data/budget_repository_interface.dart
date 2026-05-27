/// BudgetEditorService의 추상 인터페이스.
///
/// Riverpod `budgetEditorServiceProvider`가 이 타입으로 노출되므로
/// 테스트에서 mock으로 교체할 수 있다.
abstract interface class IBudgetRepository {
  Future<void> saveBudget({
    required String monthKey,
    required String? categoryId,
    required int amountLimit,
  });

  Future<void> deleteBudget({
    required String monthKey,
    required String? categoryId,
  });
}
