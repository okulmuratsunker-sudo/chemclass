import 'package:flutter/material.dart';

/// Shows a short SnackBar, mirroring the web app's `toast()`.
void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
