import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';
import 'nav_items.dart';

/// One input inside an "Add X" dialog built by [showAddRecordDialog].
///
/// Two shapes:
///   - free text (the default) — becomes a `material.TextField`, the typed
///     value (trimmed) is what [showAddRecordDialog]'s `onSubmit` receives.
///   - a dropdown — pass [options] as (value, label) pairs, e.g. a
///     client's id mapped to their display name, or an invoice's id
///     mapped to "INV004 — 500.0 (pending)". Renders as a
///     `material.DropdownButtonFormField` instead; `onSubmit` always
///     receives one of the option keys, never free text.
class RecordField {
  final String key;
  final String label;
  final String? hint;
  final bool required;
  final material.TextInputType? keyboardType;
  final int maxLines;
  final String? initialValue;
  final List<MapEntry<String, String>>? options;

  const RecordField({
    required this.key,
    required this.label,
    this.hint,
    this.required = true,
    this.keyboardType,
    this.maxLines = 1,
    this.initialValue,
    this.options,
  });
}

/// Opens a themed modal — a shadcn [Card] inside a transparent
/// `material.Dialog` (so text fields get the `Material` ancestor they
/// expect, without pulling in Material's own dialog chrome/shadows) — with
/// one input per [fields] entry, plus Cancel/Save.
///
/// Every "Add X" form in the app goes through this one dialog shell so they
/// all look and behave the same way. [onSubmit] gets the typed/selected
/// values keyed by [RecordField.key] (trimmed; empty string for a blank
/// optional field) and is responsible for building the real model and
/// persisting it (e.g. `dataProvider.addEyeExam(...)`) — the dialog closes
/// right after, so [onSubmit] shouldn't try to pop anything itself.
Future<bool?> showAddRecordDialog({
  required BuildContext context,
  required String title,
  required List<RecordField> fields,
  required void Function(Map<String, String> values) onSubmit,
  /// Which step of the client journey this form represents. No longer
  /// rendered in the dialog itself (the in-form breadcrumb was removed —
  /// see [ClientFileScreen]'s journey status row instead), kept only so
  /// call sites don't need to change if journey-aware behavior comes back.
  NavRoute? journeyStep,
}) {
  return material.showDialog<bool>(
    context: context,
    builder: (dialogContext) => material.Dialog(
      backgroundColor: Colors.transparent,
      child: _AddRecordForm(
        title: title,
        fields: fields,
        onSubmit: onSubmit,
        journeyStep: journeyStep,
      ),
    ),
  );
}

class _AddRecordForm extends StatefulWidget {
  final String title;
  final List<RecordField> fields;
  final void Function(Map<String, String> values) onSubmit;
  final NavRoute? journeyStep;

  const _AddRecordForm({
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.journeyStep,
  });

  @override
  State<_AddRecordForm> createState() => _AddRecordFormState();
}

class _AddRecordFormState extends State<_AddRecordForm> {
  late final Map<String, material.TextEditingController> _controllers;
  late final Map<String, String> _dropdownValues;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        if (field.options == null)
          field.key: material.TextEditingController(
            text: field.initialValue ?? '',
          ),
    };
    _dropdownValues = {
      for (final field in widget.fields)
        if (field.options != null)
          field.key:
              field.initialValue ??
              (field.options!.isNotEmpty ? field.options!.first.key : ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit {
    for (final field in widget.fields) {
      if (!field.required) continue;
      if (field.options != null) continue; // a dropdown always has a value
      if (_controllers[field.key]!.text.trim().isEmpty) return false;
    }
    return true;
  }

  void _submit() {
    final values = <String, String>{
      for (final field in widget.fields)
        field.key: field.options != null
            ? _dropdownValues[field.key]!
            : _controllers[field.key]!.text.trim(),
    };
    widget.onSubmit(values);
    Navigator.of(context).pop(true);
  }

  Widget _fieldInput(RecordField field) {
    if (field.options != null) {
      return material.DropdownButtonFormField<String>(
        value: _dropdownValues[field.key]!.isEmpty
            ? null
            : _dropdownValues[field.key],
        // Without this, the closed field sizes its selected-value row to
        // the option text's natural width instead of the available field
        // width — fine on wide desktop fields, but overflows on narrow
        // mobile dialogs once an option label is long (this is what threw
        // the "RenderFlex overflowed" error on the Add Prescription form).
        // `isExpanded: true` makes the row fill the field instead, so the
        // existing `maxLines: 1, overflow: ellipsis` on each option's Text
        // actually gets a chance to kick in.
        isExpanded: true,
        items: [
          for (final option in field.options!)
            material.DropdownMenuItem(
              value: option.key,
              child: Text(
                option.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) =>
            setState(() => _dropdownValues[field.key] = value ?? ''),
        decoration: material.InputDecoration(
          labelText: field.label,
          border: const material.OutlineInputBorder(),
          isDense: true,
        ),
      );
    }
    return material.TextField(
      controller: _controllers[field.key],
      keyboardType: field.keyboardType,
      maxLines: field.maxLines,
      decoration: material.InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const material.OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title).large().bold(),
                  const SizedBox(height: 16),
                  for (final field in widget.fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _fieldInput(field),
                    ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Button(
                          style: const ButtonStyle.ghost(),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(AppStrings.dialogCancelButton),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          style: const ButtonStyle.primary(),
                          onPressed: _canSubmit ? _submit : null,
                          child: Text(AppStrings.dialogSaveButton),
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
    );
  }
}
