import 'package:flutter/material.dart';

/// Shows a yes/no confirmation dialog, resolving to `true` on confirm.
Future<bool> confirmDialog(BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tamam')),
      ],
    ),
  );
  return result ?? false;
}
