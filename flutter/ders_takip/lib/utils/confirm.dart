import 'package:flutter/material.dart';

/// Shows a Yes/No confirmation dialog, mirroring the web app's `confirm()`.
/// Returns `true` only if the user confirms.
Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String content, {
  String confirmLabel = 'Evet',
  String cancelLabel = 'İptal',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}
