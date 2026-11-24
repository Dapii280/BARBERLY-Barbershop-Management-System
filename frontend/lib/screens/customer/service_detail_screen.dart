import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'booking_form_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(service.imageUrl);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('service_detail'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.content_cut,
                        size: 42,
                        color: AppColors.textMuted,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.content_cut,
                          size: 42,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!service.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
          const SizedBox(height: 10),
          Row(
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 15,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${service.durationMinutes} ${context.tr('minutes')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(service.price),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('services'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (service.description == null || service.description!.isEmpty)
                ? context.tr('no_data')
                : service.description!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AppButton(
          label: context.tr('book_now'),
          icon: Icons.event_available_outlined,
          onPressed: service.isActive
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingFormScreen(initialServiceIds: [service.id]),
                    ),
                  )
              : null,
        ),
      ),
    );
  }
}
