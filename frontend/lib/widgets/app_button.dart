import 'package:flutter/material.dart';

import '../core/theme.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == AppButtonVariant.primary || variant == AppButtonVariant.danger;
    final background = switch (variant) {
      AppButtonVariant.primary => AppColors.navy,
      AppButtonVariant.danger => AppColors.danger,
      AppButtonVariant.secondary => AppColors.surface,
      AppButtonVariant.outline => Colors.transparent,
    };
    final foreground = isFilled ? Colors.white : AppColors.navy;

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: isFilled ? const Color(0xFFCBD5E1) : AppColors.surface,
          disabledForegroundColor: isFilled ? Colors.white : AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: isFilled ? BorderSide.none : const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
