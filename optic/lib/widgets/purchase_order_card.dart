import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/purchase_order.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

(String, Color) _statusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'sent':
      return (AppStrings.poStatusSent, colorScheme.primary);
    case 'confirmed':
      return (AppStrings.poStatusConfirmed, Colors.teal.shade600);
    case 'received':
      return (AppStrings.poStatusReceived, Colors.green.shade700);
    case 'cancelled':
      return (AppStrings.poStatusCancelled, colorScheme.destructive);
    default:
      return (AppStrings.poStatusDraft, colorScheme.mutedForeground);
  }
}

class PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;

  /// Display label for [order.supplierId], resolved by the caller.
  final String supplierLabel;

  /// Navigates to that supplier's record (Suppliers screen) — kept
  /// separate from a whole-card `onTap` so the supplier name reads as its
  /// own link rather than swallowed into "tap anywhere for details".
  final VoidCallback? onSupplierTap;

  const PurchaseOrderCard({
    super.key,
    required this.order,
    required this.supplierLabel,
    this.onSupplierTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _statusStyle(order.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.totalAmount.toStringAsFixed(0)} MAD',
                ).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 4),
          if (onSupplierTap != null)
            material.InkWell(
              onTap: onSupplierTap,
              child: Text(
                supplierLabel,
                style: TextStyle(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ).small(),
            )
          else
            Text(supplierLabel).muted().small(),
          const SizedBox(height: 6),
          Text(order.description).small(),
          if (order.expectedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.cardPoExpected} ${_formatDate(order.expectedDate!)}',
            ).muted().small(),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
