/// Uses an explicitly set overall budget as the cap. Category budgets are
/// subdivisions of that cap; when there is no cap they form the total.
int effectiveBudgetTotal(
  Iterable<({String? categoryId, int amount})> budgets,
) {
  int? overall;
  var categories = 0;
  for (final budget in budgets) {
    if (budget.categoryId == null) {
      overall ??= budget.amount;
    } else {
      categories += budget.amount;
    }
  }
  return overall ?? categories;
}
