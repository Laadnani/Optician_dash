import '../models/appointment.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../data/data_provider.dart';
import '../helpers/status_chip.dart';
import '../localization/app_strings.dart';

/// One appointment on a client's file — status chip, date/reason, a
/// muted "first visit / follow-up" tag, and (new) an editable price plus a
/// tap-to-cycle paid/unpaid/not-billable control, both of which persist
/// straight back to `DataProvider` so the billing screen's weekly chart
/// picks the change up on its next rebuild.
class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  const AppointmentCard({super.key, required this.appointment});

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  late final material.TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = material.TextEditingController(
      text: _formatPrice(widget.appointment.price),
    );
  }

  @override
  void didUpdateWidget(covariant AppointmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying appointment's price changed for a reason other than
    // what's currently typed here (e.g. a different record swapped into
    // this list slot), resync the field instead of silently showing a
    // stale value.
    final typed = double.tryParse(_priceController.text.trim());
    if (typed != widget.appointment.price) {
      _priceController.text = _formatPrice(widget.appointment.price);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) =>
      price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);

  void _commitPrice(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed == widget.appointment.price) return;
    context.read<DataProvider>().updateAppointment(
      widget.appointment.copyWith(price: parsed),
    );
  }

  static const List<String> _paymentCycle = ['paid', 'unpaid', 'not_billable'];

  void _cyclePaymentStatus() {
    final currentIndex = _paymentCycle.indexOf(
      widget.appointment.paymentStatus,
    );
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % _paymentCycle.length;
    context.read<DataProvider>().updateAppointment(
      widget.appointment.copyWith(paymentStatus: _paymentCycle[nextIndex]),
    );
  }

  (IconData, Color) _paymentStyle(ColorScheme colors) {
    switch (widget.appointment.paymentStatus) {
      case 'paid':
        return (Icons.check_circle, Colors.green.shade600);
      case 'not_billable':
        return (Icons.block, colors.mutedForeground);
      case 'unpaid':
      default:
        return (Icons.radio_button_unchecked, Colors.orange.shade600);
    }
  }

  String _paymentLabel() {
    switch (widget.appointment.paymentStatus) {
      case 'paid':
        return AppStrings.appointmentPaymentPaid;
      case 'not_billable':
        return AppStrings.appointmentPaymentNotBillable;
      case 'unpaid':
      default:
        return AppStrings.appointmentPaymentUnpaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final colors = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = statusChipStyle(
      appointment.status,
      colors,
    );
    final (paymentIcon, paymentColor) = _paymentStyle(colors);
    final typeLabel = appointment.type == 'reschedule'
        ? AppStrings.appointmentTypeReschedule
        : AppStrings.appointmentTypeNew;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFieldDate} ${appointment.date}'),
          const SizedBox(height: 4),
          Text(typeLabel).muted().small(),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: material.TextField(
                    controller: _priceController,
                    keyboardType: const material.TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const material.TextStyle(fontSize: 13),
                    decoration: material.InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      suffixText: 'MAD',
                      suffixStyle: const material.TextStyle(fontSize: 11),
                      border: material.OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onSubmitted: _commitPrice,
                    onEditingComplete: () => _commitPrice(_priceController.text),
                    onTapOutside: (_) => _commitPrice(_priceController.text),
                  ),
                ),
                const SizedBox(width: 10),
                material.InkWell(
                  onTap: _cyclePaymentStatus,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(paymentIcon, size: 18, color: paymentColor),
                        const SizedBox(width: 6),
                        Text(
                          _paymentLabel(),
                          style: TextStyle(color: paymentColor),
                        ).small(),
                      ],
                    ),
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
