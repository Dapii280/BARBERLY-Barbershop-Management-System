import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'payment_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().load();
    });
  }

  Future<void> _refresh() => context.read<BookingProvider>().load(force: true);

  Future<void> _openPayment(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
    );

    if (mounted) await _refresh();
  }

  Future<void> _cancel(Booking booking) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow('cancel_booking_title'),
      message: context.trNow('cancel_booking_message'),
      confirmLabel: context.trNow('cancel_booking'),
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    final error = await context.read<BookingProvider>().cancel(booking.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.trNow('booking_cancelled')),
      ),
    );
  }

  void _showDetail(Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: _BookingDetailSheet(booking: booking),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('booking_history')),
        actions: [
          IconButton(
            onPressed: () => provider.load(force: true),
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.loading && provider.items.isEmpty) {
            return const LoadingView();
          }

          if (provider.error != null && provider.items.isEmpty) {
            return ErrorView(
              message: provider.error!,
              retryLabel: context.tr('retry'),
              onRetry: () => provider.load(force: true),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: provider.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 90),
                      EmptyState(
                        icon: Icons.event_note_outlined,
                        title: context.tr('no_bookings'),
                        message: context.tr('booking_history_subtitle'),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    itemCount: provider.items.length + 1,
                    separatorBuilder: (_, index) =>
                        SizedBox(height: index == 0 ? 12 : 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Text(
                          context.tr('booking_history_subtitle'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }

                      final booking = provider.items[index - 1];
                      return _BookingCard(
                        booking: booking,
                        onTap: () => _showDetail(booking),
                        onPay: () => _openPayment(booking),
                        onCancel: () => _cancel(booking),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onPay,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final transaction = booking.transaction;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDateLong(booking.bookingDate, languageCode),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.content_cut, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.serviceNames,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${context.tr('barber')}: ${booking.barberName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                formatTimeRange(booking.startTime, booking.endTime),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(booking.totalPrice),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          if (transaction != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                StatusBadge(status: transaction.paymentStatus, payment: true),
                if (transaction.isRejected && transaction.note != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (booking.canPay || booking.canCancel) ...[
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.canPay)
                  TextButton(
                    onPressed: onPay,
                    child: Text(context.tr('pay_now')),
                  ),
                if (booking.canCancel)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: Text(context.tr('cancel_booking')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final transaction = booking.transaction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('booking_detail'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 14),
        DetailRow(
          label: context.tr('date'),
          value: formatDateLong(booking.bookingDate, languageCode),
        ),
        DetailRow(
          label: context.tr('time'),
          value: formatTimeRange(booking.startTime, booking.endTime),
        ),
        DetailRow(label: context.tr('barber'), value: booking.barberName),
        DetailRow(label: context.tr('customer'), value: booking.customerName),
        if (booking.notes != null && booking.notes!.isNotEmpty)
          DetailRow(label: context.tr('notes'), value: booking.notes!),
        const SizedBox(height: 10),
        Text(
          context.tr('services'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ...booking.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.name} · ${item.durationMinutes} ${context.tr('minutes')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  formatRupiah(item.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(),
        ),
        DetailRow(
          label: context.tr('subtotal'),
          value: formatRupiah(booking.subtotal),
        ),
        DetailRow(
          label: '${context.tr('ppn')} 11%',
          value: formatRupiah(booking.ppnAmount),
        ),
        DetailRow(
          label: '${context.tr('tax_deduction')} 2%',
          value: '- ${formatRupiah(booking.taxDeduction)}',
          valueColor: AppColors.textSecondary,
        ),
        DetailRow(
          label: context.tr('total_payment'),
          value: formatRupiah(booking.totalPrice),
          emphasize: true,
        ),
        if (transaction != null) ...[
          const SizedBox(height: 14),
          Text(
            context.tr('transaction_status'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusBadge(status: transaction.paymentStatus, payment: true),
              const Spacer(),
              Text(
                _methodLabel(context, transaction.paymentMethod),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${context.tr('admin_note')}: ${transaction.note}',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ],
      ],
    );
  }

  String _methodLabel(BuildContext context, String method) {
    switch (method) {
      case 'cash':
        return context.tr('method_cash');
      case 'ewallet':
        return context.tr('method_ewallet');
      default:
        return context.tr('method_transfer');
    }
  }
}
