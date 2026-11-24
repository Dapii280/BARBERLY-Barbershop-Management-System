import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/barber.dart';
import '../../models/booking.dart';
import '../../providers/barber_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  static const _statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  DateTime? _date;
  int? _barberId;
  String? _status;
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BarberProvider>().load(all: true);
      await _load();
    });
  }

  Future<void> _load() {
    return context.read<BookingProvider>().load(
          date: _date == null ? null : formatIsoDate(_date!),
          barberId: _barberId,
          status: _status,
          force: true,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? todayDate(),
      firstDate: DateTime(2024),
      lastDate: todayDate().add(const Duration(days: 365)),
      helpText: context.trNow('filter_date'),
      cancelText: context.trNow('cancel'),
      confirmText: context.trNow('confirm'),
    );

    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    await _load();
  }

  Future<void> _pickBarber() async {
    final barbers = context.read<BarberProvider>().items;
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sheetContext.tr('filter_barber'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(sheetContext.tr('all_barbers')),
                      trailing: _barberId == null
                          ? const Icon(Icons.check, color: AppColors.textPrimary)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(-1),
                    ),
                    ...barbers.map(
                      (barber) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(barber.name),
                        subtitle: Text(barber.specialty ?? barber.email),
                        trailing: _barberId == barber.id
                            ? const Icon(Icons.check, color: AppColors.textPrimary)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(barber.id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => _barberId = selected == -1 ? null : selected);
    await _load();
  }

  Future<void> _changeStatus(Booking booking, String status) async {
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

  Future<void> _recordCash(Booking booking) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow('record_cash'),
      message: context.trNow('record_cash_confirm'),
      confirmLabel: context.trNow('record_cash'),
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyIds.add(booking.id));
    final error = await context.read<BookingProvider>().payCash(booking.id);
    if (!mounted) return;

    setState(() => _busyIds.remove(booking.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.trNow('cash_recorded'))),
    );
  }

  Future<void> _clearFilters() async {
    setState(() {
      _date = null;
      _barberId = null;
      _status = null;
    });
    await _load();
  }

  bool get _hasFilters =>
      _date != null || _barberId != null || _status != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final barbers = context.watch<BarberProvider>().items;
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_bookings_title')),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: AppCard(
                    onTap: _pickDate,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _date == null
                                ? context.tr('filter_date')
                                : formatDateShort(
                                    formatIsoDate(_date!),
                                    languageCode,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _date == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppCard(
                    onTap: _pickBarber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _barberName(barbers),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _barberId == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              children: [
                _filterChip(
                  label: context.tr('all_statuses'),
                  selected: _status == null,
                  onTap: () {
                    setState(() => _status = null);
                    _load();
                  },
                ),
                ..._statuses.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _filterChip(
                      label: context.tr('status_$status'),
                      selected: _status == status,
                      onTap: () {
                        setState(() => _status = status);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    context.tr('filter_active'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                    ),
                    child: Text(
                      context.tr('reset_filter'),
                      style: const TextStyle(fontSize: 11),
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
                              icon: Icons.event_busy_outlined,
                              title: context.tr('no_bookings'),
                              message: context.tr('manage_bookings_subtitle'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final booking = items[index];
                            return _ManageBookingCard(
                              booking: booking,
                              languageCode: languageCode,
                              busy: _busyIds.contains(booking.id),
                              onConfirm: () =>
                                  _changeStatus(booking, 'confirmed'),
                              onComplete: () =>
                                  _changeStatus(booking, 'completed'),
                              onCash: () => _recordCash(booking),
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

  String _barberName(List<Barber> barbers) {
    if (_barberId == null) return context.tr('all_barbers');
    for (final barber in barbers) {
      if (barber.id == _barberId) return barber.name;
    }
    return context.tr('all_barbers');
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.textPrimary,
      backgroundColor: AppColors.white,
      side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _ManageBookingCard extends StatelessWidget {
  const _ManageBookingCard({
    required this.booking,
    required this.languageCode,
    required this.busy,
    required this.onConfirm,
    required this.onComplete,
    required this.onCash,
  });

  final Booking booking;
  final String languageCode;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onCash;

  @override
  Widget build(BuildContext context) {
    final transaction = booking.transaction;
    final canRecordCash =
        !booking.isCancelled && (transaction == null || transaction.isRejected);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${booking.id} · ${formatDateShort(booking.bookingDate, languageCode)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatTimeRange(booking.startTime, booking.endTime),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            booking.serviceNames,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  booking.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.content_cut, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                booking.barberName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '${context.tr('notes')}: ${booking.notes}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                formatRupiah(booking.totalPrice),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(width: 8),
              if (transaction != null)
                StatusBadge(status: transaction.paymentStatus, payment: true)
              else
                Text(
                  context.tr('booking_not_paid'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (booking.isPending ||
              booking.isConfirmed ||
              canRecordCash) ...[
            const SizedBox(height: 6),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                if (booking.isPending)
                  TextButton(
                    onPressed: onConfirm,
                    child: Text(context.tr('confirm_booking')),
                  ),
                if (booking.isConfirmed)
                  TextButton(
                    onPressed: onComplete,
                    child: Text(context.tr('complete_booking')),
                  ),
                if (canRecordCash)
                  TextButton(
                    onPressed: onCash,
                    child: Text(context.tr('record_cash')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
