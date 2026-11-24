import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/barber.dart';
import '../../providers/barber_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/image_picker_box.dart';

class ManageBarbersScreen extends StatefulWidget {
  const ManageBarbersScreen({super.key});

  @override
  State<ManageBarbersScreen> createState() => _ManageBarbersScreenState();
}

class _ManageBarbersScreenState extends State<ManageBarbersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarberProvider>().load(all: true, force: true);
    });
  }

  Future<void> _reload() =>
      context.read<BarberProvider>().load(all: true, force: true);

  Future<void> _openForm({Barber? barber}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BarberFormSheet(barber: barber),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trNow('barber_saved'))),
      );
    }
  }

  Future<void> _delete(Barber barber) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow('delete_barber'),
      message: context.trNow('delete_barber_message'),
      confirmLabel: context.trNow('delete'),
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    final error = await context.read<BarberProvider>().remove(barber.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.trNow('barber_deleted'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BarberProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_barbers_title')),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, size: 20),
        label: Text(context.tr('add_barber')),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: Builder(
          builder: (context) {
            if (provider.loading && provider.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [LoadingView(height: 300)],
              );
            }

            if (provider.error != null && provider.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: provider.error!,
                    retryLabel: context.tr('retry'),
                    onRetry: _reload,
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                Text(
                  context.tr('manage_barbers_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (provider.items.isEmpty)
                  EmptyState(
                    icon: Icons.people_outline,
                    title: context.tr('no_barbers'),
                    action: OutlinedButton(
                      onPressed: () => _openForm(),
                      child: Text(context.tr('add_barber')),
                    ),
                  )
                else
                  ...provider.items.map(
                    (barber) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BarberAdminCard(
                        barber: barber,
                        onEdit: () => _openForm(barber: barber),
                        onDelete: () => _delete(barber),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BarberAdminCard extends StatelessWidget {
  const _BarberAdminCard({
    required this.barber,
    required this.onEdit,
    required this.onDelete,
  });

  final Barber barber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final photoUrl = resolveImageUrl(barber.photoUrl);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  )
                : CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        barber.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _ActiveChip(active: barber.isActive),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  barber.specialty ?? barber.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatTimeRange(barber.workStart, barber.workEnd),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.navy,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.successBg : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppColors.success.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Text(
        context.tr(active ? 'active' : 'inactive'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _BarberFormSheet extends StatefulWidget {
  const _BarberFormSheet({this.barber});

  final Barber? barber;

  @override
  State<_BarberFormSheet> createState() => _BarberFormSheetState();
}

class _BarberFormSheetState extends State<_BarberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _photo;
  TimeOfDay _workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 21, minute: 0);
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.barber != null;

  @override
  void initState() {
    super.initState();
    final barber = widget.barber;
    if (barber != null) {
      _nameController.text = barber.name;
      _emailController.text = barber.email;
      _phoneController.text = barber.phone ?? '';
      _specialtyController.text = barber.specialty ?? '';
      _bioController.text = barber.bio ?? '';
      _workStart = _parseTime(barber.workStart, const TimeOfDay(hour: 9, minute: 0));
      _workEnd = _parseTime(barber.workEnd, const TimeOfDay(hour: 21, minute: 0));
      _isActive = barber.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length < 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _photo = picked);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _workStart : _workEnd,
      helpText: context.trNow(start ? 'work_start' : 'work_end'),
      cancelText: context.trNow('cancel'),
      confirmText: context.trNow('confirm'),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _workStart = picked;
      } else {
        _workEnd = picked;
      }
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    final startMinutes = _workStart.hour * 60 + _workStart.minute;
    final endMinutes = _workEnd.hour * 60 + _workEnd.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _error = context.trNow('invalid_work_hours'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final fields = <String, String>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'specialty': _specialtyController.text.trim(),
      'bio': _bioController.text.trim(),
      'work_start': _formatTime(_workStart),
      'work_end': _formatTime(_workEnd),
      'is_active': _isActive ? '1' : '0',
    };

    final password = _passwordController.text;
    if (!_isEdit) {
      fields['password'] = password;
    }

    final error = await context.read<BarberProvider>().save(
          barber: widget.barber,
          fields: fields,
          photo: _photo,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(_isEdit ? 'edit_barber' : 'add_barber'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('barber_form_hint'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ImagePickerBox(
                file: _photo,
                imageUrl: widget.barber?.photoUrl,
                onTap: _pickPhoto,
                hint: context.tr('barber_photo'),
                height: 150,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('full_name'),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return context.trNow('required_field');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: context.tr('email'),
                  helperText: context.tr('barber_email_hint'),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return context.trNow('required_field');
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                    return context.trNow('invalid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText:
                      '${context.tr('phone')} (${context.tr('optional')})',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? '${context.tr('new_password')} (${context.tr('optional')})'
                      : context.tr('password'),
                  helperText: _isEdit
                      ? context.tr('barber_password_hint')
                      : null,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ),
                validator: (value) {
                  if (_isEdit) return null;
                  if ((value ?? '').length < 8) {
                    return context.trNow('password_min_length');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('barber_specialty'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('barber_bio'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () => _pickTime(start: true),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('work_start'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatTime(_workStart),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppCard(
                      onTap: () => _pickTime(start: false),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('work_end'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatTime(_workEnd),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('barber_status'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: context.tr('save'),
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
