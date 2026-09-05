import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/client.dart';
import '../localization/app_strings.dart';
import 'status_chip.dart';

/// The DashStack-style table view of [ClientsScreen] — column headers,
/// one row per client, tap-through to the file. Desktop/tablet only (see
/// `_ClientsBody`'s view toggle, which is hidden on mobile); a table this
/// wide has nowhere sensible to go on a phone, unlike the card list which
/// already stacks fine there.
///
/// [clients] is expected to already be filtered, searched, and paged by
/// the caller — this widget just renders whatever list it's handed, same
/// division of responsibility as `_Section` elsewhere in the app.
class ClientsTable extends StatelessWidget {
  final List<Client> clients;
  final void Function(Client client) onTap;

  const ClientsTable({super.key, required this.clients, required this.onTap});

  int _ageOf(Client client) {
    final now = DateTime.now();
    var age = now.year - client.dob.year;
    final birthdayPassedThisYear =
        now.month > client.dob.month ||
        (now.month == client.dob.month && now.day >= client.dob.day);
    if (!birthdayPassedThisYear) age--;
    return age;
  }

  String _dobLabel(Client client) {
    final d = client.dob;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static const _colFileNumber = 110.0;
  static const _colAge = 90.0;
  static const _colPhone = 150.0;
  static const _colInsurance = 160.0;
  static const _colStatus = 100.0;
  static const _colChevron = 32.0;
  static const _nameMinWidth = 200.0;

  double get _minTotalWidth =>
      _colFileNumber +
      _nameMinWidth +
      _colAge +
      _colPhone +
      _colInsurance +
      _colStatus +
      _colChevron +
      64;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Horizontally scrollable with a floor width — same overflow-avoidance
    // pattern used for the floating action bars/dialog footers elsewhere:
    // rather than letting 5 fixed-ish columns get crushed on a narrower
    // tablet window, the table scrolls sideways once it can't fit.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: _minTotalWidth),
        // A horizontal SingleChildScrollView hands its child an unbounded
        // max width (0..Infinity) — fine for the ConstrainedBox's minWidth
        // floor, but the Column below uses crossAxisAlignment.stretch,
        // which tries to stretch to the *max* width. Infinity in, "forces
        // an infinite width" crash out. IntrinsicWidth sizes itself to its
        // child's actual (finite) intrinsic width first, so the Column
        // downstream always sees a real number to stretch to, while the
        // outer ConstrainedBox above still enforces the column-sum floor.
        child: IntrinsicWidth(
          child: Card(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerRow(colorScheme),
                Container(height: 1, color: colorScheme.border),
                if (clients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(AppStrings.clientsTableNoResults).muted(),
                    ),
                  )
                else
                  for (var i = 0; i < clients.length; i++) ...[
                    _clientRow(context, clients[i], colorScheme),
                    if (i != clients.length - 1)
                      Container(height: 1, color: colorScheme.border),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(ColorScheme colorScheme) {
    TextStyle style() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: colorScheme.mutedForeground,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: _colFileNumber,
            child: Text(
              AppStrings.clientsTableColFileNumber.toUpperCase(),
              style: style(),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.clientsTableColName.toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _colAge,
            child: Text(AppStrings.clientsTableColAge.toUpperCase(), style: style()),
          ),
          SizedBox(
            width: _colPhone,
            child: Text(
              AppStrings.clientsTableColPhone.toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _colInsurance,
            child: Text(
              AppStrings.clientsTableColInsurance.toUpperCase(),
              style: style(),
            ),
          ),
          SizedBox(
            width: _colStatus,
            child: Text(
              AppStrings.clientsTableColStatus.toUpperCase(),
              style: style(),
            ),
          ),
          const SizedBox(width: _colChevron),
        ],
      ),
    );
  }

  Widget _statusDot(Client client, ColorScheme colorScheme) {
    final isActive = client.status == 'active';
    final color = isActive ? Colors.green.shade600 : colorScheme.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          isActive
              ? AppStrings.clientStatusActive
              : AppStrings.clientStatusInactive,
        ).muted().small(),
      ],
    );
  }

  Widget _clientRow(BuildContext context, Client client, ColorScheme colorScheme) {
    final fullName = '${client.firstName} ${client.lastName}';
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(client),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _colFileNumber,
                child: Text(
                  client.fileNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).muted().small(),
              ),
              Expanded(
                child: Row(
                  children: [
                    Avatar(initials: initial),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).semiBold(),
                          Text(
                            _dobLabel(client),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).muted().small(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: _colAge,
                child: Text('${_ageOf(client)}').muted(),
              ),
              SizedBox(
                width: _colPhone,
                child: Text(
                  client.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).muted(),
              ),
              SizedBox(
                width: _colInsurance,
                child: client.insurance.isEmpty
                    ? Text('—').muted()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(
                          label: client.insurance,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              SizedBox(
                width: _colStatus,
                child: _statusDot(client, colorScheme),
              ),
              SizedBox(
                width: _colChevron,
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
