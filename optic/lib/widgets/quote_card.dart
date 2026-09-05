import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/quote.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

(String, Color) _quoteStatusStyle(String status, ColorScheme colorScheme) {
  switch (status) {
    case 'sent':
      return (AppStrings.quoteStatusSent, colorScheme.primary);
    case 'accepted':
      return (AppStrings.quoteStatusAccepted, Colors.green.shade700);
    case 'declined':
      return (AppStrings.quoteStatusDeclined, colorScheme.destructive);
    case 'expired':
      return (AppStrings.quoteStatusExpired, Colors.orange.shade700);
    case 'draft':
    default:
      return (AppStrings.quoteStatusDraft, colorScheme.mutedForeground);
  }
}

class QuoteCard extends StatelessWidget {
  final Quote quote;

  /// Whether an [Order] already references this quote via `Order.quoteId` —
  /// when true, the "convert" action is replaced with a plain confirmation
  /// line instead of letting an accepted quote be converted twice.
  final bool alreadyConverted;

  /// Only ever called for an `accepted` quote that isn't [alreadyConverted]
  /// yet — the funnel step from Quotes into Orders.
  final VoidCallback? onConvertToOrder;

  const QuoteCard({
    super.key,
    required this.quote,
    this.alreadyConverted = false,
    this.onConvertToOrder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = _quoteStatusStyle(quote.status, colorScheme);

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${quote.totalAmount.toStringAsFixed(0)} MAD',
                ).semiBold(),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(quote.description).small(),
          if (quote.validUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              '${AppStrings.cardQuoteValidUntil} ${_formatDate(quote.validUntil!)}',
            ).muted().small(),
          ],
          if (quote.status == 'accepted') ...[
            const SizedBox(height: 10),
            if (alreadyConverted)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.quoteAlreadyConverted,
                    style: TextStyle(color: Colors.green.shade700),
                  ).small(),
                ],
              )
            else if (onConvertToOrder != null)
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: onConvertToOrder,
                  leading: const Icon(Icons.arrow_forward, size: 14),
                  child: Text(AppStrings.quoteConvertToOrder),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
