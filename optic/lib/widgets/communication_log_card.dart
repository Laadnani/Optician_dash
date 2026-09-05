import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/communication_log.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

String _channelLabel(String channel) {
  switch (channel) {
    case 'sms':
      return AppStrings.commChannelSms;
    case 'whatsapp':
      return AppStrings.commChannelWhatsapp;
    case 'email':
      return AppStrings.commChannelEmail;
    case 'inPerson':
      return AppStrings.commChannelInPerson;
    case 'phone':
    default:
      return AppStrings.commChannelPhone;
  }
}

class CommunicationLogCard extends StatelessWidget {
  final CommunicationLog log;
  const CommunicationLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(log.subject).semiBold()),
              StatusChip(
                label: log.direction == 'inbound'
                    ? AppStrings.commDirectionInbound
                    : AppStrings.commDirectionOutbound,
                color: log.direction == 'inbound'
                    ? colorScheme.primary
                    : Colors.teal.shade600,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_channelLabel(log.channel)).muted().small(),
          if (log.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(log.note).small(),
          ],
          if (log.followUpRequired) ...[
            const SizedBox(height: 6),
            StatusChip(
              label: AppStrings.commFollowUpRequired,
              color: Colors.orange.shade700,
            ),
          ],
        ],
      ),
    );
  }
}
