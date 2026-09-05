import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/localization/app_strings.dart';

/// Stand-in for a screen that hasn't been built yet. Already wired into
/// [AppShell] (sidebar/drawer, resize-settle) and the shared nav list, so
/// as you build "Appointments", "Clients", etc., you swap the relevant
/// entry in `nav_items.dart` from `PlaceholderScreen(...)` to the real
/// screen — no shell/navigation wiring left to redo.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final NavRoute navRoute;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.navRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, navRoute),
      bodyBuilder: (context, breakpoint) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(title).semiBold(),
              const SizedBox(height: 4),
              Text(AppStrings.placeholderComingSoon).muted(),
            ],
          ),
        ),
      ),
    );
  }
}
