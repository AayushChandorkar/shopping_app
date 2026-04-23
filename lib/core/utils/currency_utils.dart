import 'package:flutter/material.dart';

/// Approximate exchange rates expressed as **INR per 1 unit of the currency**.
/// These are fixed (no network). Adjust here if you want fresher rates.
const Map<String, double> _inrRates = {
  '₹ INR': 1.0,
  '\$ USD': 83.0,
  '€ EUR': 90.0,
  '£ GBP': 105.0,
};

/// Icons that match each supported currency label.
const Map<String, IconData> _currencyIcons = {
  '₹ INR': Icons.currency_rupee_rounded,
  '\$ USD': Icons.attach_money_rounded,
  '€ EUR': Icons.euro_rounded,
  '£ GBP': Icons.currency_pound_rounded,
};

/// Returns the icon that matches the given currency label (e.g. "₹ INR").
/// Falls back to the generic currency_exchange icon for unknown inputs.
IconData currencyIconFor(String currency) {
  return _currencyIcons[currency] ?? Icons.currency_exchange_rounded;
}

/// Converts [value] from the [from] currency to the [to] currency using the
/// fixed INR-based rate table above.
///
/// Example: convertPrice(100, '\$ USD', '₹ INR') => 8300.0
double convertPrice(double value, String from, String to) {
  if (from == to) return value;
  final fromRate = _inrRates[from];
  final toRate = _inrRates[to];
  if (fromRate == null || toRate == null) return value;
  // value (in `from`) -> INR -> `to`
  return value * fromRate / toRate;
}
