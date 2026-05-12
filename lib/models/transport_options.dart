import 'package:flutter/material.dart';

/// Representa as opções de transporte
class TransportOption {
  final String value;
  final String label;
  final IconData icon;

  const TransportOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
