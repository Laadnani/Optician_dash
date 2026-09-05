import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../models/frame_selection.dart';
import '../localization/app_strings.dart';
import '../helpers/status_chip.dart';

class FrameSelectionCard extends StatelessWidget {
  final FrameSelectionSession session;

  /// Display label for [FrameSelectionSession.selectedFrameId], resolved
  /// by the caller (the screen already has the frame catalog loaded).
  final String? selectedFrameLabel;

  const FrameSelectionCard({
    super.key,
    required this.session,
    this.selectedFrameLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = session.selectedFrameId != null;
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.method == 'virtual'
                      ? AppStrings.frameSelectionMethodVirtual
                      : AppStrings.frameSelectionMethodInStore,
                ).semiBold(),
              ),
              StatusChip(
                label: hasSelection
                    ? (selectedFrameLabel ?? session.selectedFrameId!)
                    : AppStrings.cardFrameSelectionUndecided,
                color: hasSelection
                    ? Colors.green.shade700
                    : colorScheme.mutedForeground,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.cardFrameSelectionTried} ${session.framesTried.length}',
          ).muted().small(),
          if (session.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(session.notes).small(),
          ],
        ],
      ),
    );
  }
}
