import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format integer cents to a currency string.
/// e.g. 412000 → "$4,120.00"
String formatCents(int cents, {String currency = 'USD'}) {
  final dollars = cents / 100.0;
  return NumberFormat.currency(locale: 'en_US', symbol: r'$').format(dollars);
}

/// Returns a color based on how many days remain until [expiryDateStr].
/// - expired or < 30 days: red
/// - 30–60 days: amber
/// - > 60 days: green
Color expiryColor(String expiryDateStr) {
  final expiry = DateTime.tryParse(expiryDateStr);
  if (expiry == null) return Colors.grey;
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0) return Colors.red;
  if (days <= 30) return Colors.red;
  if (days <= 60) return Colors.amber;
  return Colors.green;
}
