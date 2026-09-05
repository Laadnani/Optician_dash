import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/data/data_provider.dart';
import 'package:optic/models/appointment.dart';
import 'package:optic/localization/app_strings.dart';
import 'add_record_dialog.dart';
import 'nav_items.dart';

/// Opens the "Add appointment" dialog — one shared form for all three
/// places an appointment gets booked from (dashboard quick action,
/// calendar, and a client file's Appointments tab).
///
/// Pass [initialClientId] when opening from an already-known client
/// (their file) — the client dropdown is skipped entirely since there's
/// nothing to pick. Pass [initialDate] to prefill the date (e.g. whichever
/// day is selected on the calendar); defaults to today.
Future<void> showAddAppointmentDialog(
  BuildContext context, {
  String? initialClientId,
  DateTime? initialDate,
}) {
  final dataProvider = context.read<DataProvider>();
  final date = initialDate ?? DateTime.now();
  final dateText = _formatDate(date);

  final fields = <RecordField>[
    if (initialClientId == null)
      RecordField(
        key: 'clientId',
        label: AppStrings.recordFieldClient,
        options: [
          for (final client in dataProvider.clients)
            MapEntry(
              client.id,
              '${client.firstName} ${client.lastName} (${client.fileNumber})',
            ),
        ],
      ),
    RecordField(
      key: 'date',
      label: AppStrings.cardFieldDate,
      hint: 'YYYY-MM-DD',
      initialValue: dateText,
    ),
    RecordField(key: 'time', label: AppStrings.recordFieldTime, hint: 'HH:MM (24h)', initialValue: '09:00'),
    RecordField(key: 'reason', label: AppStrings.recordFieldReason, hint: AppStrings.hintAppointmentReason),
  ];

  return showAddRecordDialog(
    context: context,
    title: AppStrings.addDialogAppointmentTitle,
    fields: fields,
    journeyStep: NavRoute.calendar,
    onSubmit: (values) {
      final clientId = initialClientId ?? values['clientId']!;
      if (clientId.isEmpty) return; // no clients to pick from — nothing to save

      final parsedDate = DateTime.tryParse(values['date']!) ?? date;
      final timeParts = values['time']!.split(':');
      final hour = timeParts.isNotEmpty
          ? int.tryParse(timeParts[0]) ?? 9
          : 9;
      final minute = timeParts.length > 1
          ? int.tryParse(timeParts[1]) ?? 0
          : 0;

      dataProvider.addAppointment(
        Appointment(
          id: 'A${DateTime.now().millisecondsSinceEpoch}',
          clientId: clientId,
          date: DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            hour,
            minute,
          ),
          reason: values['reason']!,
          status: 'scheduled',
        ),
      );
    },
  );
}

String _formatDate(DateTime d) {
  final yyyy = d.year.toString().padLeft(4, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
