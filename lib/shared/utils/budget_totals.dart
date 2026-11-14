/// An overall budget is the cap; category budgets are subdivisions of it.
/// Without an overall cap, the category budgets make up the total.
int effectiveBudgetTotal(
  Iterable<({
    String? categoryId,
    int amount,
    DateTime modifiedAt,
    String id,
  })> budgets,
) {
  ({String? categoryId, int amount, DateTime modifiedAt, String id})? overall;
  var categories = 0;
  for (final budget in budgets) {
    if (budget.categoryId != null) {
      categories += budget.amount;
    } else if (overall == null ||
        budget.modifiedAt.isAfter(overall.modifiedAt) ||
        (budget.modifiedAt.isAtSameMomentAs(overall.modifiedAt) &&
            budget.id.compareTo(overall.id) > 0)) {
      // Retain duplicate rows, but use the most recently edited cap.
      overall = budget;
    }
  }
  return overall?.amount ?? categories;
}
