import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  /// Shares content using the native platform share sheet.
  ///
  /// [title] - Title for the shared content.
  /// [text] - Body text to share (e.g. a message or description).
  /// [url] - A URL to share. If provided alongside [text], it will be
  ///   appended to the text automatically.
  /// [context] - BuildContext used to determine share sheet anchor position (iPad).
  static void share({
    String? title,
    String? text,
    String? url,
    BuildContext? context,
  }) {
    Rect? rect;
    if (context != null) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        rect = box.localToGlobal(Offset.zero) & box.size;
      }
    }

    final shareText = [
      if (text != null) text,
      if (url != null) url,
    ].join('\n');

    SharePlus.instance.share(ShareParams(
      title: title,
      text: shareText.isNotEmpty ? shareText : null,
      uri: url != null ? Uri.tryParse(url) : null,
      sharePositionOrigin: rect,
    ));
  }
}
