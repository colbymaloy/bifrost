import 'dart:js_interop';

import 'package:web/web.dart' as web;

class ShareUtils {
  ShareUtils._();

  /// Shares content using the Web Share API, with a fallback to opening a new tab.
  ///
  /// [title] - Title for the shared content.
  /// [text] - Body text to share (e.g. a message or description).
  /// [url] - A URL to share. Falls back to opening this URL in a new tab if
  ///   the Web Share API is unavailable.
  /// [context] - Unused on web. Accepted for API compatibility with mobile.
  static void share({
    String? title,
    String? text,
    String? url,
    Object? context,
  }) {
    final shareText = [
      if (text != null) text,
      if (url != null) url,
    ].join('\n');

    final shareData = web.ShareData(
      title: title ?? '',
      text: shareText.isNotEmpty ? shareText : '',
      url: url ?? '',
    );

    final navigator = web.window.navigator;

    // Use Web Share API if available, otherwise open in a new tab.
    if (navigator.canShare(shareData)) {
      navigator.share(shareData);
    } else if (url != null) {
      web.window.open(url, '_blank');
    }
  }
}
