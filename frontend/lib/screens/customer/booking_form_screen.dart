import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/barber.dart';
import '../../models/service.dart';
import '../../providers/barber_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/service_card.dart';
import 'payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    this.initialServiceIds = const [],
    this.initialBarberId,
  });

  final List<int> initialServiceIds;
  final int? initialBarberId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final Set<int> _selectedServiceIds = {};
  final TextEditingController _notesController = TextEditingController();

  late DateTime _selectedDate;
  int? _barberId;
  String? _selectedTime;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = todayDate();
    _barberId = widget.initialBarberId;
    _selectedServiceIds.addAll(widget.initialServiceIds);

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      context.read<ServiceProvider>().load(),
      context.read<BarberProvider>().load(),
    ]);

    if (!mounted) return;
    _loadSlots();
  }

  List<Service> get _selectedServices {
    final items = context.read<ServiceProvider>().items;
    return items.where((service) => _selectedServiceIds.contains(service.id)).toList();
  }

  Barber? get _selectedBarber {
    final items = context.read<BarberProvider>().items;
    for (final barber in items) {
      if (barber.id == _barberId) return barber;
    }
    return null;
  }

  int get _totalDuration {
    final services = _selectedServices;
    if (services.isEmpty) return 30;
    return services.fold(0, (total, service) => total + service.durationMinutes);
  }

  double get _subtotal =>
      _selectedServices.fold(0.0, (total, service) => total + service.price);

  double get _ppn => _subtotal * AppConstants.ppnRate;

  double get _deduction => _subtotal * AppConstants.taxDeductionRate;

  double get _totalPrice => (_subtotal + _ppn - _deduction).roundToDouble();

  void _loadSlots() {
    final barberId = _barberId;
    final barberProvider = context.read<BarberProvider>();

    if (barberId == null) {
      barberProvider.clearSlots();
      return;
    }

    barberProvider.loadAvailability(
      barberId: barberId,
      date: formatIsoDate(_selectedDate),
      duration: _totalDuration,
    );
  }

  void _toggleService(Service service) {
    setState(() {
      if (!_selectedServiceIds.remove(service.id)) {
        _selectedServiceIds.add(service.id);
      }
      _selectedTime = null;
    });
    _loadSlots();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: todayDate(),
      lastDate: todayDate().add(const Duration(days: 90)),
      helpText: context.trNow('select_date'),
      cancelText: context.trNow('cancel'),
      confirmText: context.trNow('confirm'),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = picked;
      _selectedTime = null;
    });
    _loadSlots();
  }

  Future<void> _pickBarber() async {
    final barbers = context.read<BarberProvider>().items;
    if (barbers.isEmpty) return;

    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetContext.tr('choose_barber'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: barbers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    final photoUrl = resolveImageUrl(barber.photoUrl);
                    final isSelected = barber.id == _barberId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.of(sheetContext).pop(barber.id),
                      leading: Container(
                        width: 42,
                        height: 42,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: photoUrl.isEmpty
                            ? Center(
                                child: Text(
                                  barber.initial,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )
                            : CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover),
                      ),
                      title: Text(barber.name),
                      subtitle: Text(
                        barber.specialty ?? barber.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.amber)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !mounted || chosen == _barberId) return;

    setState(() {
      _barberId = chosen;
      _selectedTime = null;
    });
    _loadSlots();
  }

  Future<void> _submit() async {
    if (_selectedServices.isEmpty) {
      _showMessage(context.trNow('no_service_selected'));
      return;
    }
    if (_barberId == null) {
      _showMessage(context.trNow('choose_barber_hint'));
      return;
    }
    if (_selectedTime == null) {
      _showMessage(context.trNow('select_time'));
      return;
    }

    setState(() => _submitting = true);

    final booking = await context.read<BookingProvider>().create(
          barberId: _barberId!,
          bookingDate: formatIsoDate(_selectedDate),
          startTime: _selectedTime!,
          serviceIds: _selectedServices.map((service) => service.id).toList(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (booking == null) {
      _showMessage(context.read<BookingProvider>().error ?? context.trNow('err_generic'));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trNow('booking_created'))),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final barberProvider = context.watch<BarberProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final selectedBarber = _selectedBarber;
    final languageCode = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('booking_form_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _sectionTitle(context.tr('select_services')),
          Text(
            context.tr('select_services_hint'),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          if (serviceProvider.loading && serviceProvider.items.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
            )
          else
            ...serviceProvider.items.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ServiceCard(
                  service: service,
                  showDescription: false,
                  selected: _selectedServiceIds.contains(service.id),
                  onTap: () => _toggleService(service),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _sectionTitle(context.tr('choose_barber')),
          const SizedBox(height: 8),
          AppCard(
            onTap: _pickBarber,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: selectedBarber == null
                      ? const Icon(Icons.person_outline, size: 20, color: AppColors.textMuted)
                      : _barberAvatar(selectedBarber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedBarber?.name ?? context.tr('choose_barber_hint'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (selectedBarber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatTimeRange(selectedBarber.workStart, selectedBarber.workEnd),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context.tr('select_date')),
          const SizedBox(height: 8),
          AppCard(
            onTap: _pickDate,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatDateLong(formatIsoDate(_selectedDate), languageCode),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context.tr('available_slots')),
          const SizedBox(height: 8),
          _slotSection(barberProvider),
          const SizedBox(height: 18),
          TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.tr('notes'),
              hintText: context.tr('notes_hint'),
              alignLabelWithHint: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle(context.tr('bill_detail')),
          const SizedBox(height: 8),
          AppCard(
            color: AppColors.surface,
            child: Column(
              children: [
                DetailRow(
                  label: context.tr('subtotal'),
                  value: formatRupiah(_subtotal),
                ),
                DetailRow(
                  label:
                      '${context.tr('ppn')} ${(AppConstants.ppnRate * 100).round()}%',
                  value: formatRupiah(_ppn),
                ),
                DetailRow(
                  label:
                      '${context.tr('tax_deduction')} ${(AppConstants.taxDeductionRate * 100).round()}%',
                  value: '- ${formatRupiah(_deduction)}',
                  valueColor: AppColors.textSecondary,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                DetailRow(
                  label: context.tr('total_payment'),
                  value: formatRupiah(_totalPrice),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AppButton(
          label: context.tr('create_booking'),
          icon: Icons.check,
          loading: _submitting,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _barberAvatar(Barber barber) {
    final url = resolveImageUrl(barber.photoUrl);
    if (url.isEmpty) {
      return Center(
        child: Text(
          barber.initial,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      );
    }
    return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _slotSection(BarberProvider provider) {
    if (_barberId == null) {
      return Text(
        context.tr('slots_hint'),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    if (provider.slotsLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
      );
    }

    if (provider.slotsError != null) {
      return Text(
        provider.slotsError!,
        style: const TextStyle(fontSize: 12, color: AppColors.danger),
      );
    }

    if (provider.slots.isEmpty) {
      return Text(
        context.tr('no_slots'),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.slots.map((slot) {
        final isSelected = _selectedTime == slot;

        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _selectedTime = slot),
          selectedColor: AppColors.amber,
          backgroundColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? AppColors.amber : AppColors.border,
          ),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
      }).toList(),
    );
  }
}
