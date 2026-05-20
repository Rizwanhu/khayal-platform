/// Maps technical errors to short, actionable copy (HCI: visibility of status,
/// help users recognize & recover from errors).
String userFacingNetworkOrGenericError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network') ||
      raw.contains('connection') ||
      raw.contains('timed out')) {
    return 'No internet connection. Check Wi‑Fi or mobile data and try again.';
  }
  if (raw.contains('401') || raw.contains('403') || raw.contains('jwt')) {
    return 'Your session may have expired. Sign out and sign in again.';
  }
  return 'Something went wrong. Please try again in a moment.';
}
