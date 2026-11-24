import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().load(force: true);
    });
  }

  Future<void> _reload() => context.read<UserProvider>().load(force: true);

  Future<void> _changeRole(User user, String role) async {
    if (user.role == role || !mounted) return;

    setState(() => _busyIds.add(user.id));
    final error = await context.read<UserProvider>().updateUser(
          id: user.id,
          role: role,
        );
    if (!mounted) return;

    setState(() => _busyIds.remove(user.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.trNow('role_updated'))),
    );
  }

  Future<void> _toggleActive(User user, bool value) async {
    setState(() => _busyIds.add(user.id));
    final error = await context.read<UserProvider>().updateUser(
          id: user.id,
          isActive: value,
        );
    if (!mounted) return;

    setState(() => _busyIds.remove(user.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? context.trNow('user_updated'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_users_title')),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Text(
                  context.tr('manage_users_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (provider.items.isEmpty)
                  EmptyState(
                    icon: Icons.group_outlined,
                    title: context.tr('no_data'),
                  )
                else
                  ...provider.items.map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserCard(
                        user: user,
                        isSelf: user.id == currentUserId,
                        busy: _busyIds.contains(user.id),
                        onRoleChanged: (role) => _changeRole(user, role),
                        onActiveChanged: (value) => _toggleActive(user, value),
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

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.onRoleChanged,
    required this.onActiveChanged,
  });

  final User user;
  final bool isSelf;
  final bool busy;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    user.initial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
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
                        Flexible(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(you)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Text(
                        user.phone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              RoleBadge(role: user.role),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: isSelf
                    ? Text(
                        context.tr('cannot_edit_self'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            context.tr('user_role'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            enabled: !busy,
                            initialValue: user.role,
                            onSelected: onRoleChanged,
                            itemBuilder: (menuContext) => [
                              for (final role in const [
                                'admin',
                                'barber',
                                'customer',
                              ])
                                PopupMenuItem(
                                  value: role,
                                  child: Text(menuContext.tr('role_$role')),
                                ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr('role_${user.role}'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.expand_more,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  children: [
                    Text(
                      context.tr('account_status'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Switch(
                      value: user.isActive,
                      onChanged: isSelf ? null : onActiveChanged,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
