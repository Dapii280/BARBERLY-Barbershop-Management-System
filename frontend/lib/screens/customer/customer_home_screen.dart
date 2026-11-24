import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/barber.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barber_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/service_card.dart';
import 'barber_list_screen.dart';
import 'booking_form_screen.dart';
import 'service_detail_screen.dart';
import 'service_list_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(false));
  }

  Future<void> _load(bool force) async {
    await Future.wait([
      context.read<ServiceProvider>().load(force: force),
      context.read<BarberProvider>().load(force: force),
    ]);
  }

  Future<void> _openBooking({List<int> serviceIds = const [], int? barberId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(
          initialServiceIds: serviceIds,
          initialBarberId: barberId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final services = context.watch<ServiceProvider>();
    final barbers = context.watch<BarberProvider>();
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr('home_greeting')}, $firstName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('home_title'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Avatar(name: user?.name ?? '', photoUrl: user?.photoUrl),
                ],
              ),
              const SizedBox(height: 22),
              _promoCard(context),
              const SizedBox(height: 26),
              SectionHeader(title: context.tr('quick_access')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _quickCard(
                      icon: Icons.content_cut,
                      title: context.tr('services_title'),
                      subtitle:
                          '${services.items.length} ${context.tr('services_count')}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ServiceListScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickCard(
                      icon: Icons.people_outline,
                      title: context.tr('barbers_title'),
                      subtitle:
                          '${barbers.items.length} ${context.tr('barbers_count')}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BarberListScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: context.tr('popular_services'),
                actionLabel: context.tr('view_all'),
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServiceListScreen()),
                ),
              ),
              const SizedBox(height: 10),
              if (services.loading && services.items.isEmpty)
                const LoadingView(height: 140)
              else if (services.items.isEmpty)
                Text(
                  context.tr('no_services'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...services.items.take(3).map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ServiceCard(
                          service: service,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailScreen(service: service),
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              SectionHeader(
                title: context.tr('our_barbers'),
                actionLabel: context.tr('view_all'),
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BarberListScreen()),
                ),
              ),
              const SizedBox(height: 10),
              if (barbers.loading && barbers.items.isEmpty)
                const LoadingView(height: 110)
              else if (barbers.items.isEmpty)
                Text(
                  context.tr('no_barbers'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: barbers.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final barber = barbers.items[index];
                      return SizedBox(
                        width: 132,
                        child: _BarberMiniCard(
                          barber: barber,
                          onTap: () => _openBooking(barberId: barber.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('promo_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('promo_desc'),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openBooking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.tr('promo_button')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(photoUrl);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: url.isEmpty
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            )
          : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
    );
  }
}

class _BarberMiniCard extends StatelessWidget {
  const _BarberMiniCard({required this.barber, required this.onTap});

  final Barber barber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(barber.photoUrl);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: url.isEmpty
                ? Center(
                    child: Text(
                      barber.initial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text(
            barber.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            barber.specialty ?? context.tr('barber'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
