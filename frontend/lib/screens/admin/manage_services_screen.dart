import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/service_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/image_picker_box.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().load(all: true, force: true);
    });
  }

  Future<void> _reload() =>
      context.read<ServiceProvider>().load(all: true, force: true);

  Future<void> _openForm({Service? service}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ServiceFormSheet(service: service),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trNow('service_saved'))),
      );
    }
  }

  Future<void> _delete(Service service) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow('delete_service'),
      message: context.trNow('delete_service_message'),
      confirmLabel: context.trNow('delete'),
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    final error = await context.read<ServiceProvider>().remove(service.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.trNow('service_deleted'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_services_title')),
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
        label: Text(context.tr('add_service')),
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
                  context.tr('manage_services_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (provider.items.isEmpty)
                  EmptyState(
                    icon: Icons.design_services_outlined,
                    title: context.tr('no_services'),
                    action: OutlinedButton(
                      onPressed: () => _openForm(),
                      child: Text(context.tr('add_service')),
                    ),
                  )
                else
                  ...provider.items.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ServiceAdminCard(
                        service: service,
                        onEdit: () => _openForm(service: service),
                        onDelete: () => _delete(service),
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

class _ServiceAdminCard extends StatelessWidget {
  const _ServiceAdminCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(service.imageUrl);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 68,
              height: 68,
              child: imageUrl.isEmpty
                  ? Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.content_cut,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.content_cut,
                          size: 22,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
            ),
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
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!service.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          context.tr('service_inactive'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${service.durationMinutes} ${context.tr('minutes')} · '
                  '${formatRupiah(service.price)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

class _ServiceFormSheet extends StatefulWidget {
  const _ServiceFormSheet({this.service});

  final Service? service;

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  bool _isActive = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    if (service != null) {
      _nameController.text = service.name;
      _descriptionController.text = service.description ?? '';
      _priceController.text = service.price.toStringAsFixed(0);
      _durationController.text = '${service.durationMinutes}';
      _isActive = service.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _image = picked);
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await context.read<ServiceProvider>().save(
          service: widget.service,
          fields: {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': _priceController.text.trim(),
            'duration_minutes': _durationController.text.trim(),
            'is_active': _isActive ? '1' : '0',
          },
          image: _image,
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
                context.tr(_isEdit ? 'edit_service' : 'add_service'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('service_form_hint'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ImagePickerBox(
                file: _image,
                imageUrl: widget.service?.imageUrl,
                onTap: _pickImage,
                hint: context.tr('service_image'),
                height: 150,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('service_name'),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return context.trNow('required_field');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('service_description'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('service_price'),
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        final price = double.tryParse((value ?? '').trim());
                        if (price == null || price <= 0) {
                          return context.trNow('invalid_price');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.tr('service_duration'),
                      ),
                      validator: (value) {
                        final duration = int.tryParse((value ?? '').trim());
                        if (duration == null || duration <= 0) {
                          return context.trNow('invalid_duration');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('service_status'),
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
