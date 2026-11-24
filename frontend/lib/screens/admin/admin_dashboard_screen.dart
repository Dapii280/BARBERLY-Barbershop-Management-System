import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/booking.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import 'manage_barbers_screen.dart';
import 'manage_services_screen.dart';
import 'manage_users_screen.dart';
import 'verify_transactions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => context.read<DashboardProvider>().load(force: true);

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final summary = provider.summary;
    final user = context.watch<AuthProvider>().user;
    final languageCode = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard_title')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(
          builder: (context) {
            if (provider.loading && summary == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [LoadingView(height: 320)],
              );
            }

            if (provider.error != null && summary == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: provider.error!,
                    retryLabel: context.tr('retry'),
                    onRetry: _load,
                  ),
                ],
              );
            }

            if (summary == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.dashboard_outlined,
                    title: context.tr('no_data'),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  '${context.tr('welcome_admin')}, ${user?.name ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr('dashboard_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_note_outlined,
                        label: context.tr('today_bookings'),
                        value: '${summary.todayBookings}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_outlined,
                        label: context.tr('pending_transactions'),
                        value: '${summary.pendingTransactions}',
                        highlight: summary.pendingTransactions > 0,
                        onTap: () => _open(const VerifyTransactionsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: context.tr('today_revenue'),
                        value: formatRupiah(summary.todayRevenue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        label: context.tr('total_revenue'),
                        value: formatRupiah(summary.totalRevenue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_outline,
                        label: context.tr('total_customers'),
                        value: '${summary.totalCustomers}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.content_cut,
                        label: context.tr('total_barbers'),
                        value: '${summary.totalBarbers}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.tr('booking_status_summary')),
                const SizedBox(height: 10),
                AppCard(
                  child: Row(
                    children: [
                      _StatusCount(
                        label: context.tr('status_pending'),
                        value: summary.statusCounts.pending,
                        color: AppColors.amber,
                      ),
                      _StatusCount(
                        label: context.tr('status_confirmed'),
                        value: summary.statusCounts.confirmed,
                        color: AppColors.info,
                      ),
                      _StatusCount(
                        label: context.tr('status_completed'),
                        value: summary.statusCounts.completed,
                        color: AppColors.success,
                      ),
                      _StatusCount(
                        label: context.tr('status_cancelled'),
                        value: summary.statusCounts.cancelled,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.tr('quick_menu')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.content_cut,
                        label: context.tr('manage_barbers'),
                        onTap: () => _open(const ManageBarbersScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.group_outlined,
                        label: context.tr('manage_users'),
                        onTap: () => _open(const ManageUsersScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.fact_check_outlined,
                        label: context.tr('verify_transactions'),
                        onTap: () => _open(const VerifyTransactionsScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.design_services_outlined,
                        label: context.tr('manage_services'),
                        onTap: () => _open(const ManageServicesScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.tr('top_services')),
                const SizedBox(height: 10),
                AppCard(
                  child: summary.topServices.isEmpty
                      ? Text(
                          context.tr('no_top_services'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < summary.topServices.length; i++) ...[
                              if (i > 0) const Divider(height: 18),
                              _TopServiceRow(service: summary.topServices[i]),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.tr('booking_history')),
                const SizedBox(height: 10),
                AppCard(
                  child: summary.recentBookings.isEmpty
                      ? Text(
                          context.tr('no_bookings'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < summary.recentBookings.length; i++) ...[
                              if (i > 0) const Divider(height: 18),
                              _RecentBookingRow(
                                booking: summary.recentBookings[i],
                                languageCode: languageCode,
                              ),
                            ],
                          ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: highlight ? AppColors.amber : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: highlight ? AppColors.amber : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: value.length > 10 ? 16 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: highlight ? AppColors.amber : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 17, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopServiceRow extends StatelessWidget {
  const _TopServiceRow({required this.service});

  final TopService service;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.content_cut, size: 14, color: AppColors.navy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${service.totalBooked} ${context.tr('booked_times')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(
          formatRupiah(service.revenue),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _RecentBookingRow extends StatelessWidget {
  const _RecentBookingRow({required this.booking, required this.languageCode});

  final Booking booking;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatDateShort(booking.bookingDate, languageCode)} · '
                '${formatTime(booking.startTime)} · ${booking.barberName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRupiah(booking.totalPrice),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            StatusBadge(status: booking.status),
          ],
        ),
      ],
    );
  }
}
