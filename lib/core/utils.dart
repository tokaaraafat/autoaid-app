import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callNumber(BuildContext context, String number) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not start a call to $number')));
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String? requiredField(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null;
