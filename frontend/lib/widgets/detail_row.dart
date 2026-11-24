import 'package:flutter/material.dart';

import '../core/theme.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
    this.labelColor,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;
  final Color? labelColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasize ? 14 : 13,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
                color: labelColor ?? AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 16 : 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ??
                    (emphasize ? AppColors.amber : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
