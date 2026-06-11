import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Format integer cents to a currency string using the given ISO currency code.
/// e.g. formatCents(412000) → "$4,120.00", formatCents(412000, currency: 'EUR') → "€4,120.00"
String formatCents(int cents, {String currency = 'USD'}) {
  final amount = cents / 100.0;
  try {
    final formatted = NumberFormat.simpleCurrency(
      locale: 'en_US',
      name: currency,
    ).format(amount);
    return _ensureSymbolSpacing(formatted);
  } catch (_) {
    // Unknown currency code — fall back to the code as a prefix.
    return '$currency ${NumberFormat('#,##0.00', 'en_US').format(amount)}';
  }
}

/// Inserts a space between multi-letter currency symbols and the amount.
/// e.g. intl formats LKR as "Rs0.00" — we want "Rs 0.00".
String _ensureSymbolSpacing(String formatted) {
  final match = RegExp(r'^(-?)([A-Za-z]{2,})(\d)').firstMatch(formatted);
  if (match == null) return formatted;
  final sign = match.group(1) ?? '';
  final symbol = match.group(2)!;
  final rest = formatted.substring(sign.length + symbol.length);
  return '$sign$symbol $rest';
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
