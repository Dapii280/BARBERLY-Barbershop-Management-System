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
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class BarberScheduleScreen extends StatefulWidget {
  const BarberScheduleScreen({super.key});

  @override
  State<BarberScheduleScreen> createState() => _BarberScheduleScreenState();
}

class _BarberScheduleScreenState extends State<BarberScheduleScreen> {
  late DateTime _selectedDate;
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = todayDate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    return context.read<BookingProvider>().load(
          date: formatIsoDate(_selectedDate),
          force: true,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: todayDate().subtract(const Duration(days: 365)),
      lastDate: todayDate().add(const Duration(days: 365)),
      helpText: context.trNow('filter_date'),
      cancelText: context.trNow('cancel'),
      confirmText: context.trNow('confirm'),
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _load();
  }

  Future<void> _updateStatus(Booking booking, String status) async {
    final isComplete = status == 'completed';
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow(isComplete ? 'complete_booking' : 'confirm_booking'),
      message: context.trNow(
        isComplete ? 'complete_booking_message' : 'confirm_booking_message',
      ),
      confirmLabel: context.trNow(isComplete ? 'complete' : 'confirm_booking'),
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyIds.add(booking.id));
    final error = await context.read<BookingProvider>().updateStatus(
          booking.id,
          status,
        );
    if (!mounted) return;

    setState(() => _busyIds.remove(booking.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              context.trNow(isComplete ? 'status_completed' : 'status_confirmed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('schedule_title')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: AppCard(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.navy,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('filter_date'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateLong(
                            formatIsoDate(_selectedDate),
                            languageCode,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text(
                    '${items.length} ${context.tr('nav_bookings').toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.loading && items.isEmpty) {
                  return const LoadingView();
                }

                if (provider.error != null && items.isEmpty) {
                  return ErrorView(
                    message: provider.error!,
                    retryLabel: context.tr('retry'),
                    onRetry: _load,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _load,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.event_available_outlined,
                              title: context.tr('no_schedule'),
                              message: context.tr('schedule_subtitle'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final booking = items[index];
                            return _ScheduleCard(
                              booking: booking,
                              busy: _busyIds.contains(booking.id),
                              onConfirm: () => _updateStatus(booking, 'confirmed'),
                              onComplete: () => _updateStatus(booking, 'completed'),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.booking,
    required this.busy,
    required this.onConfirm,
    required this.onComplete,
  });

  final Booking booking;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final transaction = booking.transaction;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatTimeRange(booking.startTime, booking.endTime),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (booking.customerPhone != null && booking.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  booking.customerPhone!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.content_cut, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.serviceNames,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${context.tr('notes')}: ${booking.notes}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                formatRupiah(booking.totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 8),
              if (transaction != null)
                StatusBadge(status: transaction.paymentStatus, payment: true),
            ],
          ),
          if (booking.isPending || booking.isConfirmed) ...[
            const SizedBox(height: 8),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : booking.isPending
                      ? TextButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check_circle_outline, size: 17),
                          label: Text(context.tr('confirm_booking')),
                        )
                      : TextButton.icon(
                          onPressed: onComplete,
                          icon: const Icon(Icons.task_alt, size: 17),
                          label: Text(context.tr('complete_booking')),
                        ),
            ),
          ],
        ],
      ),
    );
  }
}
