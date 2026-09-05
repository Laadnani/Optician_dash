import 'package:shadcn_flutter/shadcn_flutter.dart';

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickAction({required this.label, required this.icon, required this.onTap});
}

class QuickActionsBar extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsBar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (a) => Button.outline(
              onPressed: a.onTap,
              leading: Icon(a.icon, size: 16),
              child: Text(a.label),
            ),
          )
          .toList(),
    );
  }
}
