import 'package:flutter/material.dart';

/// Shows a short SnackBar, mirroring the web app's `msg()` toast for
/// direct, synchronous action feedback.
void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
