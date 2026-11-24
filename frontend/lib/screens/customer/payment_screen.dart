import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/image_picker_box.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _proof;
  String _method = 'transfer';
  bool _submitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _proof = picked);
    }
  }

  Future<void> _submit() async {
    if (_proof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trNow('proof_required'))),
      );
      return;
    }

    setState(() => _submitting = true);

    final error = await context.read<BookingProvider>().pay(
          bookingId: widget.booking.id,
          paymentMethod: _method,
          proof: _proof!,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trNow('proof_sent'))),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final languageCode = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('payment_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            context.tr('payment_subtitle'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('payment_for'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${booking.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    booking.serviceNames,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DetailRow(
                  label: context.tr('date'),
                  value: formatDateLong(booking.bookingDate, languageCode),
                ),
                DetailRow(
                  label: context.tr('time'),
                  value: formatTimeRange(booking.startTime, booking.endTime),
                ),
                DetailRow(
                  label: context.tr('barber'),
                  value: booking.barberName,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                DetailRow(
                  label: context.tr('total_payment'),
                  value: formatRupiah(booking.totalPrice),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('payment_method'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MethodOption(
                  label: context.tr('method_transfer'),
                  icon: Icons.account_balance_outlined,
                  selected: _method == 'transfer',
                  onTap: () => setState(() => _method = 'transfer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodOption(
                  label: context.tr('method_ewallet'),
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _method == 'ewallet',
                  onTap: () => setState(() => _method = 'ewallet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('upload_proof'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ImagePickerBox(
            file: _proof,
            onTap: _pickProof,
            hint: context.tr('proof_hint'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('payment_info'),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AppButton(
          label: context.tr('send_proof'),
          icon: Icons.upload_file_outlined,
          loading: _submitting,
          onPressed: _submit,
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy.withValues(alpha: 0.06) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.navy : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
