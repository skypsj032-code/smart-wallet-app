/// Consistent, conservative key for on-device suggestions. Distinct business
/// names should never be merged simply because their amounts happen to match.
String normalizeNotificationMerchant(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
