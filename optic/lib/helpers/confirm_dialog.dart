import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

/// A themed yes/no confirmation dialog — e.g. "Sign out?". Returns `true`
/// only if the destructive/primary action was pressed, `false`/`null`
/// otherwise, so callers can safely do `if (await showConfirmDialog(...) ==
/// true) { ... }`.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return material.showDialog<bool>(
    context: context,
    builder: (dialogContext) => material.Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title).large().bold(),
                  const SizedBox(height: 8),
                  Text(message).muted(),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Button(
                          style: const ButtonStyle.ghost(),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(AppStrings.dialogCancelButton),
                        ),
                        const SizedBox(width: 8),
                        PrimaryButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Text(confirmLabel),
                        ),
                      ],
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
