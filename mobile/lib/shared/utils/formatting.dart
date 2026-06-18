import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/currencies.dart';
import 'distance_unit.dart';

/// Format integer cents to a currency string using the given ISO currency code.
/// e.g. formatCents(412000) → "$4,120.00", formatCents(412000, currency: 'EUR') → "€4,120.00"
///
/// When the amount has no fractional cents (value % 100 == 0) the decimal part
/// is omitted — e.g. LKR 2679300 cents → "Rs 26,793" not "Rs 26,793.00".
/// This matches real-world LKR usage where prices are always whole rupees.
String formatCents(int cents, {String currency = kFallbackCurrency}) {
  final amount = cents / 100.0;
  try {
    final formatted = NumberFormat.simpleCurrency(
      locale: 'en_US',
      name: currency,
    ).format(amount);
    final spaced = _ensureSymbolSpacing(formatted);
    return cents % 100 == 0 ? _stripDecimalZeros(spaced) : spaced;
  } catch (_) {
    final formatted = NumberFormat('#,##0.00', 'en_US').format(amount);
    final value = cents % 100 == 0 ? _stripDecimalZeros(formatted) : formatted;
    return '$currency $value';
  }
}

/// Removes a trailing ".00" (or ",00") decimal-zero suffix produced by intl.
String _stripDecimalZeros(String s) =>
    s.replaceAll(RegExp(r'[.,]00$'), '');

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

/// Canonical economy formatter: converts backend L/100km to the user's unit.
///
/// This is the single source of truth — both the garage card and vehicle detail
/// call this so they always show the same string for the same data.
///
/// km  → "X.X km/L"
/// mi  → "X.X mpg"
/// null / ≤ 0 → "—"
String formatEconomyFromStats(double? lPer100km, DistanceUnit unit) =>
    formatEconomy(lPer100km, unit);

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
