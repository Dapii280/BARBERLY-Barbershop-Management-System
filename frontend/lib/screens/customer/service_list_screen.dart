import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/service_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/service_card.dart';
import 'service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('services_title'))),
      body: RefreshIndicator(
        onRefresh: () => provider.load(force: true),
        child: Builder(
          builder: (context) {
            if (provider.loading && provider.items.isEmpty) {
              return const LoadingView();
            }

            if (provider.error != null && provider.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: provider.error!,
                    retryLabel: context.tr('retry'),
                    onRetry: () => provider.load(force: true),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: provider.items.isEmpty ? 2 : provider.items.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 14 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    context.tr('services_subtitle'),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  );
                }

                if (provider.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.content_cut,
                    title: context.tr('no_services'),
                  );
                }

                final service = provider.items[index - 1];
                return ServiceCard(
                  service: service,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(service: service),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
