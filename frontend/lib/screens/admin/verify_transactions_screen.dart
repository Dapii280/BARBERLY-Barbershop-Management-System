import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../providers/locale_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class VerifyTransactionsScreen extends StatefulWidget {
  const VerifyTransactionsScreen({super.key});

  @override
  State<VerifyTransactionsScreen> createState() =>
      _VerifyTransactionsScreenState();
}

class _VerifyTransactionsScreenState extends State<VerifyTransactionsScreen> {
  static const _filters = ['waiting', 'paid', 'rejected'];

  String? _filter = 'waiting';
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() {
    return context.read<TransactionProvider>().load(
          paymentStatus: _filter,
          force: true,
        );
  }

  void _setFilter(String? value) {
    setState(() => _filter = value);
    _load();
  }

  Future<void> _approve(TransactionModel transaction) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.trNow('approve_transaction'),
      message: context.trNow('approve_transaction_message'),
      confirmLabel: context.trNow('approve'),
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyIds.add(transaction.id));
    final error = await context.read<TransactionProvider>().verify(
          id: transaction.id,
          paymentStatus: 'paid',
        );
    if (!mounted) return;

    setState(() => _busyIds.remove(transaction.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.trNow('transaction_approved')),
      ),
    );
  }

  Future<void> _reject(TransactionModel transaction) async {
    final note = await _askRejectionNote();
    if (note == null || !mounted) return;

    if (note.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trNow('note_required'))),
      );
      return;
    }

    setState(() => _busyIds.add(transaction.id));
    final error = await context.read<TransactionProvider>().verify(
          id: transaction.id,
          paymentStatus: 'rejected',
          note: note.trim(),
        );
    if (!mounted) return;

    setState(() => _busyIds.remove(transaction.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.trNow('transaction_rejected')),
      ),
    );
  }

  Future<String?> _askRejectionNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('reject_transaction')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.tr('reject_transaction_message'),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: dialogContext.tr('rejection_note'),
                hintText: dialogContext.tr('rejection_note_hint'),
                alignLabelWithHint: true,
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(dialogContext.tr('cancel')),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(dialogContext.tr('reject')),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  void _viewProof(TransactionModel transaction) {
    final url = resolveImageUrl(transaction.proofUrl);
    if (url.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dialogContext.tr('proof_of_payment'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final languageCode = context.watch<LocaleProvider>().languageCode;
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('verify_title')),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              children: [
                _filterChip(
                  label: context.tr('all'),
                  selected: _filter == null,
                  onTap: () => _setFilter(null),
                ),
                ..._filters.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _filterChip(
                      label: context.tr('filter_$status'),
                      selected: _filter == status,
                      onTap: () => _setFilter(status),
                    ),
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
                              icon: Icons.receipt_long_outlined,
                              title: context.tr('no_transactions'),
                              message: context.tr('verify_subtitle'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final transaction = items[index];
                            return _TransactionCard(
                              transaction: transaction,
                              languageCode: languageCode,
                              busy: _busyIds.contains(transaction.id),
                              onViewProof: () => _viewProof(transaction),
                              onApprove: () => _approve(transaction),
                              onReject: () => _reject(transaction),
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
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.white,
      side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.languageCode,
    required this.busy,
    required this.onViewProof,
    required this.onApprove,
    required this.onReject,
  });

  final TransactionModel transaction;
  final String languageCode;
  final bool busy;
  final VoidCallback onViewProof;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final hasProof =
        transaction.proofUrl != null && transaction.proofUrl!.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  '#${transaction.bookingId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(status: transaction.paymentStatus, payment: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(transaction.amount),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  transaction.customerName ?? '-',
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
                transaction.barberName ?? '-',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                transaction.bookingDate == null
                    ? '-'
                    : '${formatDateShort(transaction.bookingDate!, languageCode)} · '
                        '${formatTime(transaction.startTime ?? '')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                _methodLabel(context, transaction.paymentMethod),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (transaction.paidAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${context.tr('paid_at')}: ${formatDateTime(transaction.paidAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${context.tr('admin_note')}: ${transaction.note}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.danger,
              ),
            ),
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else ...[
            const SizedBox(height: 6),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                if (hasProof)
                  TextButton.icon(
                    onPressed: onViewProof,
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: Text(context.tr('view_proof')),
                  ),
                if (transaction.isWaiting) ...[
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: Text(context.tr('reject')),
                  ),
                  TextButton(
                    onPressed: onApprove,
                    child: Text(context.tr('approve')),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _methodLabel(BuildContext context, String method) {
    switch (method) {
      case 'cash':
        return context.tr('method_cash');
      case 'ewallet':
        return context.tr('method_ewallet');
      default:
        return context.tr('method_transfer');
    }
  }
}
