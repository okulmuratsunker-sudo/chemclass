import 'package:flutter/material.dart';

/// Shows a short SnackBar for direct, synchronous action feedback.
void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
