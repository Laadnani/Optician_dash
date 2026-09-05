import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

/// The small "what do you want to do with this card?" chooser every
/// tappable client-linked record card in the app opens onto instead of
/// jumping straight to the read-only detail dialog: view the record's full
/// detail (see `showRecordDetailDialog`), jump straight to the client it
/// belongs to, or edit its fields in place. One shared shell so every
/// module's card behaves the same way on tap.
Future<void> showRecordActionMenu({
  required BuildContext context,
  required String title,
  String? subtitle,
  required VoidCallback onViewDetails,
  required VoidCallback onGoToClient,
  required VoidCallback onEdit,
}) {
  return material.showDialog<void>(
    context: context,
    builder: (dialogContext) => material.Dialog(
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
                  Text(title).large().bold(),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle).muted().small(),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Button.outline(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onViewDetails();
                      },
                      leading: const Icon(Icons.visibility_outlined, size: 16),
                      child: Text(AppStrings.recordActionViewDetails),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Button.outline(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onGoToClient();
                      },
                      leading: const Icon(Icons.person_outline, size: 16),
                      child: Text(AppStrings.recordActionGoToClient),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Button.outline(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onEdit();
                      },
                      leading: const Icon(Icons.edit_outlined, size: 16),
                      child: Text(AppStrings.recordActionEdit),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Button(
                      style: const ButtonStyle.ghost(),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(AppStrings.dialogCloseButton),
                    ),
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
