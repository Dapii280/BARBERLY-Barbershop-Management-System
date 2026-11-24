import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.payment = false});

  final String status;
  final bool payment;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Text(
        context.tr(payment ? 'payment_status_$status' : 'status_$status'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    switch (status) {
      case 'confirmed':
        return (AppColors.infoBg, AppColors.info);
      case 'completed':
      case 'paid':
        return (AppColors.successBg, AppColors.success);
      case 'cancelled':
      case 'rejected':
        return (AppColors.dangerBg, AppColors.danger);
      case 'pending':
      case 'waiting':
      default:
        return (const Color(0xFFFFFBEB), AppColors.amber);
    }
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (role) {
      'admin' => AppColors.navy,
      'barber' => AppColors.amber,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        context.tr('role_$role'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
