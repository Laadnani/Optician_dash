import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/client.dart';
import 'status_chip.dart';

/// One row in [ClientsScreen]'s list — avatar, name, file #/DOB/phone, an
/// insurance chip when there is one, and a chevron. Tapping anywhere on the
/// row calls [onTap] (the screen wires that to `context.go('/clients/$id')`).
class ClientListTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const ClientListTile({super.key, required this.client, required this.onTap});

  int get _age {
    final now = DateTime.now();
    var age = now.year - client.dob.year;
    final birthdayPassedThisYear =
        now.month > client.dob.month ||
        (now.month == client.dob.month && now.day >= client.dob.day);
    if (!birthdayPassedThisYear) age--;
    return age;
  }

  String get _dobLabel {
    final d = client.dob;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = '${client.firstName} ${client.lastName}';
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Card(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Avatar(initials: initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).semiBold(),
                    const SizedBox(height: 2),
                    Text(
                      '${client.fileNumber} · $_dobLabel ($_age) · ${client.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).muted().small(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (client.insurance.isNotEmpty)
                StatusChip(label: client.insurance, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: client.status == 'active'
                      ? Colors.green.shade600
                      : theme.colorScheme.mutedForeground,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
