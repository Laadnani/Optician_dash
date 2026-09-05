import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

/// One label/value line inside [showRecordDetailDialog].
class DetailRow {
  final String label;
  final String value;
  const DetailRow(this.label, this.value);
}

/// One button rendered under a detail dialog's rows — e.g. "Convert to
/// order", "View linked order". [onPressed] runs after the dialog itself
/// has already closed, so it's free to open another dialog or navigate.
class DetailAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool primary;

  const DetailAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.primary = false,
  });
}

/// A read-only "view record" dialog — the tap-through every record card in
/// the app opens onto, one level deeper than the summary already shown on
/// the card itself. Every module reuses this one shell (same look as
/// [showAddRecordDialog]'s form shell) instead of building its own detail
/// screen, so tapping any card anywhere in the app behaves the same way.
Future<void> showRecordDetailDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<DetailRow> rows,
  List<DetailAction> actions = const [],
  VoidCallback? onDelete,
}) {
  return material.showDialog<void>(
    context: context,
    builder: (dialogContext) => material.Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title).large().bold(),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle).muted().small(),
                    ],
                    const SizedBox(height: 16),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(row.label).muted().small(),
                            ),
                            Expanded(child: Text(row.value)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (onDelete != null)
                          Button(
                            style: const ButtonStyle.destructive(),
                            leading: const Icon(Icons.delete_outline, size: 14),
                            onPressed: () => _confirmDelete(
                              dialogContext,
                              onDelete: onDelete,
                            ),
                            child: Text(AppStrings.deleteButtonLabel),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  style: const ButtonStyle.ghost(),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Text(AppStrings.dialogCloseButton),
                                ),
                                for (final action in actions) ...[
                                  const SizedBox(width: 8),
                                  if (action.primary)
                                    PrimaryButton(
                                      leading: action.icon != null
                                          ? Icon(action.icon, size: 14)
                                          : null,
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        action.onPressed();
                                      },
                                      child: Text(action.label),
                                    )
                                  else
                                    Button.outline(
                                      leading: action.icon != null
                                          ? Icon(action.icon, size: 14)
                                          : null,
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        action.onPressed();
                                      },
                                      child: Text(action.label),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A small "are you sure?" step shown on top of the still-open detail
/// dialog when its Delete button is pressed. Confirming pops both dialogs
/// (this one and the detail dialog underneath) and then runs [onDelete].
void _confirmDelete(
  BuildContext dialogContext, {
  required VoidCallback onDelete,
}) {
  material.showDialog<void>(
    context: dialogContext,
    builder: (confirmContext) => material.Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.deleteConfirmTitle).large().bold(),
                  const SizedBox(height: 6),
                  Text(AppStrings.deleteConfirmMessage).muted().small(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(
                        style: const ButtonStyle.ghost(),
                        onPressed: () => Navigator.of(confirmContext).pop(),
                        child: Text(AppStrings.dialogCloseButton),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        style: const ButtonStyle.destructive(),
                        onPressed: () {
                          Navigator.of(confirmContext).pop();
                          Navigator.of(dialogContext).pop();
                          onDelete();
                        },
                        child: Text(AppStrings.deleteConfirmButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
