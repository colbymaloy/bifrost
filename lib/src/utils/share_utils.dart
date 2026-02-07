/// Cross-platform share utilities.
///
/// Uses conditional imports to select the correct implementation:
/// - Mobile (dart:io): Uses `share_plus` for native share sheets
/// - Web (dart:html): Uses the Web Share API with fallback to window.open
export 'share_utils_mobile.dart'
    if (dart.library.html) 'share_utils_web.dart';
