import 'package:flutter/material.dart' as material;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:optic/controllers/theme_controller.dart';
import 'package:optic/controllers/dashboard_prefs_controller.dart';
import 'package:optic/controllers/tenant_session.dart';
import 'package:optic/models/dashboard_widget_id.dart';
import 'package:optic/constants.dart';
import 'package:optic/app_shell.dart';
import 'package:optic/helpers/breakpoint.dart';
import 'package:optic/helpers/nav_items.dart';
import 'package:optic/localization/app_strings.dart';
import 'package:optic/widgets/user_avatar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navItems: (context) => buildAppNavItems(context, NavRoute.settings),
      bodyBuilder: (context, breakpoint) =>
          _SettingsBody(breakpoint: breakpoint),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  final Breakpoint breakpoint;

  const _SettingsBody({required this.breakpoint});

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.navSettings).large().bold(),
          const SizedBox(height: 20),
          // Horizontally scrollable so narrow/mobile widths don't force all
          // four tab labels into less room than they need — shadcn's `Tabs`
          // sizes its internal Row to the labels' natural width
          // (`mainAxisSize: min`), which overflows once that's tighter than
          // the tab band's own natural content width. Wrapping it in a
          // horizontal `SingleChildScrollView` gives it unbounded width to
          // lay out in, and turns the overflow into a swipe/scroll instead.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Tabs(
              index: _tabIndex,
              onChanged: (value) => setState(() => _tabIndex = value),
              children: [
                TabItem(child: Text(AppStrings.settingsAppearanceTab)),
                TabItem(child: Text(AppStrings.settingsDashboardTab)),
                TabItem(child: Text(AppStrings.settingsAccountTab)),
                TabItem(child: Text(AppStrings.settingsNotificationsTab)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IndexedStack(
            index: _tabIndex,
            children: [
              _AppearanceTab(breakpoint: widget.breakpoint),
              const _DashboardPrefsTab(),
              const _AccountTab(),
              _ComingSoonTab(title: AppStrings.settingsNotificationsTab),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String title;
  const _ComingSoonTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

/// Settings → Account: a read-only profile view of the signed-in staff
/// member and their shop. Every field here is sourced from Firestore via
/// [TenantSession] (`/users/{uid}` and `/tenants/{tenantId}`, resolved right
/// after sign-in — see `tenant_session.dart`) rather than kept as separate
/// UI state, and none of it is editable from inside the app EXCEPT the
/// profile picture — the one field a signed-in user can change themselves
/// (see `TenantSession.uploadPhoto` + the narrowed `firestore.rules` for
/// why that one exception is safe).
class _AccountTab extends StatefulWidget {
  const _AccountTab();

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  bool _isSubmitting = false;
  String? _message;
  bool _messageIsError = false;

  // Maps a picked file's extension to the MIME type used as the
  // `data:<mime>;base64,...` prefix in TenantSession.uploadPhoto —
  // image_picker's gallery source always returns one of these on every
  // platform this app targets (Web/Android/iOS), so an unmatched
  // extension isn't expected in practice; falling back to jpeg rather
  // than failing outright.
  String _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final XFile? picked;
    try {
      // `ImageSource.gallery` opens the photo library on Android/iOS, and
      // the OS's native file/folder browser on desktop and in a desktop
      // browser (there's no "gallery" concept there) — image_picker
      // already handles that distinction per-platform on its own.
      //
      // maxWidth/imageQuality are deliberately tight (a small avatar, not a
      // photo) — this is stored as Base64 directly on the Firestore doc
      // (see TenantSession.uploadPhoto), not uploaded to Storage, so
      // keeping the source image small is what keeps the encoded string
      // comfortably under Firestore's ~1 MiB document cap.
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 320,
        imageQuality: 70,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = AppStrings.settingsAccountPhotoError;
        _messageIsError = true;
      });
      return;
    }
    if (picked == null) return; // user backed out of the picker

    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final bytes = await picked.readAsBytes();
      await context.read<TenantSession>().uploadPhoto(
        bytes,
        contentType: _contentTypeFor(picked.name),
      );
      if (!mounted) return;
      setState(() {
        _message = AppStrings.settingsAccountPhotoSuccess;
        _messageIsError = false;
      });
    } on PhotoTooLargeException {
      if (!mounted) return;
      setState(() {
        _message = AppStrings.settingsAccountPhotoTooLarge;
        _messageIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = AppStrings.settingsAccountPhotoError;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _row(BuildContext context, String label, String? value) {
    final displayValue = (value == null || value.isEmpty)
        ? AppStrings.settingsAccountValueNotSet
        : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label).muted(),
          ),
          Expanded(
            child: Text(displayValue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantSession = context.watch<TenantSession>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.settingsAccountIntro).muted().small(),
            const SizedBox(height: 16),
            // Profile picture: the one self-service edit on this whole tab
            // — see TenantSession.uploadPhoto + the narrowed
            // firestore.rules `allow update` for why this is safe even
            // though everything else here is read-only.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserAvatar(size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.settingsAccountPhotoLabel).semiBold(),
                      const SizedBox(height: 8),
                      Button(
                        style: const ButtonStyle.primary(),
                        onPressed: _isSubmitting ? null : _pickAndUploadPhoto,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: material.CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(AppStrings.settingsAccountPhotoChangeButton),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _message!,
                          style: _messageIsError
                              ? TextStyle(color: colorScheme.destructive)
                              : null,
                        ).small(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _row(
              context,
              AppStrings.settingsAccountEmailLabel,
              tenantSession.email,
            ),
            const Divider(),
            _row(
              context,
              AppStrings.settingsAccountBusinessNameLabel,
              tenantSession.shopName,
            ),
            const Divider(),
            _row(
              context,
              AppStrings.settingsAccountOwnerNameLabel,
              tenantSession.ownerName,
            ),
            const Divider(),
            _row(
              context,
              AppStrings.settingsAccountPhoneLabel,
              tenantSession.ownerPhone,
            ),
            const Divider(),
            _row(
              context,
              AppStrings.settingsAccountSubscriptionLabel,
              tenantSession.plan,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings → Dashboard: one switch per [DashboardWidgetId], letting a
/// doctor/optician trim the "everything at a glance" dashboard down to
/// just what they check daily. Unlike the Appearance tab, toggles apply
/// (and persist) immediately — there's no draft/Save step, since flipping
/// one boolean is a low-stakes, instantly-reversible action, not a
/// multi-field theme commit.
class _DashboardPrefsTab extends StatelessWidget {
  const _DashboardPrefsTab();

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<DashboardPrefsController>();

    if (!prefs.isLoaded) {
      return const Center(child: material.CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.settingsDashboardIntro).muted().small(),
            const SizedBox(height: 16),
            for (final id in DashboardWidgetId.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(id.icon, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(id.label),
                          Text(id.description).muted().small(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    material.Switch(
                      value: prefs.isEnabled(id),
                      onChanged: (_) => prefs.toggle(id),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The theme-customization panel. Every control edits LOCAL draft state
/// only — nothing touches [ThemeController] (and nothing persists) until
/// "Save changes" is pressed, which commits everything at once via
/// `ThemeController.applyTheme(...)`. "Reset" discards the draft and goes
/// back to whatever's currently applied. The preview panel always reflects
/// the draft, so you see changes before committing to them.
class _AppearanceTab extends StatefulWidget {
  final Breakpoint breakpoint;

  const _AppearanceTab({required this.breakpoint});

  @override
  State<_AppearanceTab> createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<_AppearanceTab> {
  late bool _isDarkMode;
  late int _colorFamilyIndex;
  late double _radius;
  late double _widgetScaling;
  late double _textScaling;
  late double _iconScaling;
  late double _buttonScaling;
  late double _surfaceOpacity;
  late double _surfaceBlur;
  late double _cardBorderWidth;
  late double _cardShadowIntensity;
  late double _buttonShadowIntensity;
  late int _languageIndex;
  late int _secondaryColorIndex;
  late int _tertiaryColorIndex;
  late int _backgroundColorIndex;
  late double _backgroundColorOpacity;
  bool _initialized = false;

  void _loadDraftFrom(ThemeController controller) {
    _isDarkMode = controller.isDarkMode;
    _colorFamilyIndex = controller.colorFamilyIndex;
    _radius = controller.radius;
    _widgetScaling = controller.widgetScaling;
    _textScaling = controller.textScaling;
    _iconScaling = controller.iconScaling;
    _buttonScaling = controller.buttonScaling;
    _surfaceOpacity = controller.surfaceOpacity;
    _surfaceBlur = controller.surfaceBlur;
    _cardBorderWidth = controller.cardBorderWidth;
    _cardShadowIntensity = controller.cardShadowIntensity;
    _buttonShadowIntensity = controller.buttonShadowIntensity;
    _languageIndex = controller.languageIndex;
    _secondaryColorIndex = controller.secondaryColorIndex;
    _tertiaryColorIndex = controller.tertiaryColorIndex;
    _backgroundColorIndex = controller.backgroundColorIndex;
    _backgroundColorOpacity = controller.backgroundColorOpacity;
    _initialized = true;
  }

  bool _hasUnsavedChanges(ThemeController controller) {
    return _isDarkMode != controller.isDarkMode ||
        _colorFamilyIndex != controller.colorFamilyIndex ||
        _radius != controller.radius ||
        _widgetScaling != controller.widgetScaling ||
        _textScaling != controller.textScaling ||
        _iconScaling != controller.iconScaling ||
        _buttonScaling != controller.buttonScaling ||
        _surfaceOpacity != controller.surfaceOpacity ||
        _surfaceBlur != controller.surfaceBlur ||
        _cardBorderWidth != controller.cardBorderWidth ||
        _cardShadowIntensity != controller.cardShadowIntensity ||
        _buttonShadowIntensity != controller.buttonShadowIntensity ||
        _languageIndex != controller.languageIndex ||
        _secondaryColorIndex != controller.secondaryColorIndex ||
        _tertiaryColorIndex != controller.tertiaryColorIndex ||
        _backgroundColorIndex != controller.backgroundColorIndex ||
        _backgroundColorOpacity != controller.backgroundColorOpacity;
  }

  ThemeData get _draftTheme {
    final family = kColorFamilies[_colorFamilyIndex];
    final base = _isDarkMode ? family.dark : family.light;
    var scheme = ThemeController.applyAccentOverrides(
      base,
      isDarkMode: _isDarkMode,
      secondaryColorIndex: _secondaryColorIndex,
      tertiaryColorIndex: _tertiaryColorIndex,
    );
    if (_backgroundColorIndex >= 0 && _backgroundColorIndex < kColorFamilies.length) {
      final tintFamily = kColorFamilies[_backgroundColorIndex];
      final tint = _isDarkMode ? tintFamily.dark.primary : tintFamily.light.primary;
      scheme = scheme.copyWith(
        background: () => ThemeController.applyColorTint(
          scheme.background,
          tint,
          _backgroundColorOpacity,
        ),
      );
    }
    // Geist is always the app's typography now (no longer a toggle).
    return ThemeData(
      colorScheme: scheme,
      radius: _radius,
      scaling: _widgetScaling,
      surfaceOpacity: _surfaceOpacity,
      surfaceBlur: _surfaceBlur,
      typography: const Typography.geist(),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    double step = 0.05,
  }) {
    // On mobile/tablet the fixed 140px label + 44px value columns leave the
    // Slider almost no track width to drag — a handful of pixels at most —
    // so on those breakpoints the row is a tap target instead: it opens a
    // dialog with +/- stepper buttons, which needs no drag precision at
    // all. Desktop keeps the inline slider since it has the width for one.
    if (widget.breakpoint != Breakpoint.desktop) {
      final colorScheme = Theme.of(context).colorScheme;
      return material.InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openStepperDialog(
          label: label,
          value: value,
          min: min,
          max: max,
          step: step,
          onChanged: onChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text(value.toStringAsFixed(2)).muted(),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            // Using Flutter's own Slider (aliased `material`) rather than
            // guessing shadcn_flutter's slider API/param names — same
            // reasoning as the CircularProgressIndicator used elsewhere in
            // this app.
            child: material.Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
            ).muted(),
          ),
        ],
      ),
    );
  }

  /// The mobile/tablet replacement for dragging a cramped inline slider —
  /// a small dialog with minus/plus buttons that step [value] by [step]
  /// (clamped to [min]/[max]) and call [onChanged] on every tap, live,
  /// same as dragging the desktop slider would. Built on `material.Dialog`
  /// + a shadcn `Card` inside, matching `confirm_dialog.dart`'s established
  /// pattern for a themed dialog over `material.showDialog`'s positioning.
  void _openStepperDialog({
    required String label,
    required double value,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
  }) {
    material.showDialog<void>(
      context: context,
      builder: (dialogContext) {
        double current = value;
        return material.StatefulBuilder(
          builder: (context, setDialogState) {
            void adjust(double delta) {
              final next = (current + delta).clamp(min, max).toDouble();
              if (next == current) return;
              setDialogState(() => current = next);
              onChanged(next);
            }

            return material.Dialog(
              backgroundColor: Colors.transparent,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label).large().bold(),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.ghost(
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    current <= min ? null : () => adjust(-step),
                              ),
                              Expanded(
                                child: Text(
                                  current.toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                ).large().semiBold(),
                              ),
                              IconButton.ghost(
                                icon: const Icon(Icons.add),
                                onPressed:
                                    current >= max ? null : () => adjust(step),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PrimaryButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(AppStrings.dialogCloseButton),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    if (!themeController.isLoaded) {
      // Briefly true on first launch, while shared_preferences loads.
      return const Center(child: material.CircularProgressIndicator());
    }

    // Seed the draft from whatever's currently persisted, exactly once —
    // after that, the draft is independent of the controller until Save
    // (or Reset) is pressed, even if the controller happens to rebuild
    // this widget for unrelated reasons.
    if (!_initialized) {
      _loadDraftFrom(themeController);
    }

    final hasChanges = _hasUnsavedChanges(themeController);
    final isDesktop = widget.breakpoint == Breakpoint.desktop;

    final controlsCard = Card(
      child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      material.Switch(
                        value: _isDarkMode,
                        onChanged: (v) => setState(() => _isDarkMode = v),
                      ),
                      const SizedBox(width: 8),
                      Text(AppStrings.settingsDarkModeLabel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.settingsColorSchemeLabel).semiBold(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < kColorFamilies.length; i++)
                        Button(
                          style: i == _colorFamilyIndex
                              ? const ButtonStyle.primary()
                              : const ButtonStyle.ghost(),
                          onPressed: () =>
                              setState(() => _colorFamilyIndex = i),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? kColorFamilies[i].dark.primary
                                      : kColorFamilies[i].light.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(kColorFamilies[i].name),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.settingsLanguageLabel).semiBold(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < kLanguages.length; i++)
                        Button(
                          style: i == _languageIndex
                              ? const ButtonStyle.primary()
                              : const ButtonStyle.ghost(),
                          onPressed: () => setState(() => _languageIndex = i),
                          child: Text(kLanguages[i].name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sliderRow(
                    label: AppStrings.settingsRadiusLabel,
                    value: _radius,
                    min: 0,
                    max: 2,
                    step: 0.1,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsWidgetScalingLabel,
                    value: _widgetScaling,
                    min: 0.6,
                    max: 1.5,
                    onChanged: (v) => setState(() => _widgetScaling = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsTextScalingLabel,
                    value: _textScaling,
                    min: 0.8,
                    max: 1.4,
                    onChanged: (v) => setState(() => _textScaling = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsIconScalingLabel,
                    value: _iconScaling,
                    min: 0.7,
                    max: 1.6,
                    onChanged: (v) => setState(() => _iconScaling = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsSurfaceOpacityLabel,
                    value: _surfaceOpacity,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() => _surfaceOpacity = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsSurfaceBlurLabel,
                    value: _surfaceBlur,
                    min: 0,
                    max: 20,
                    step: 1,
                    onChanged: (v) => setState(() => _surfaceBlur = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsCardBorderLabel,
                    value: _cardBorderWidth,
                    min: 0,
                    max: 3,
                    step: 0.25,
                    onChanged: (v) => setState(() => _cardBorderWidth = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsCardShadowLabel,
                    value: _cardShadowIntensity,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() => _cardShadowIntensity = v),
                  ),
                  _sliderRow(
                    label: AppStrings.settingsButtonShadowLabel,
                    value: _buttonShadowIntensity,
                    min: 0,
                    max: 1,
                    onChanged: (v) =>
                        setState(() => _buttonShadowIntensity = v),
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.settingsBackgroundColorLabel).semiBold(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Button(
                        style: _backgroundColorIndex < 0
                            ? const ButtonStyle.primary()
                            : const ButtonStyle.ghost(),
                        onPressed: () =>
                            setState(() => _backgroundColorIndex = -1),
                        child: Text(
                          AppStrings.settingsBackgroundColorDefaultOption,
                        ),
                      ),
                      for (var i = 0; i < kColorFamilies.length; i++)
                        Button(
                          style: i == _backgroundColorIndex
                              ? const ButtonStyle.primary()
                              : const ButtonStyle.ghost(),
                          onPressed: () =>
                              setState(() => _backgroundColorIndex = i),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? kColorFamilies[i].dark.primary
                                      : kColorFamilies[i].light.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(kColorFamilies[i].name),
                            ],
                          ),
                        ),
                    ],
                  ),
                  _sliderRow(
                    label: AppStrings.settingsBackgroundOpacityLabel,
                    value: _backgroundColorOpacity,
                    min: 0,
                    max: 1,
                    onChanged: (v) =>
                        setState(() => _backgroundColorOpacity = v),
                  ),
                  const SizedBox(height: 12),
                  if (hasChanges)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        AppStrings.settingsUnsavedChangesNote,
                        maxLines: 2,
                      ).muted().small(),
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Button(
                          style: const ButtonStyle.primary(),
                          onPressed: hasChanges
                              ? () {
                                  themeController.applyTheme(
                                    isDarkMode: _isDarkMode,
                                    colorFamilyIndex: _colorFamilyIndex,
                                    radius: _radius,
                                    widgetScaling: _widgetScaling,
                                    textScaling: _textScaling,
                                    iconScaling: _iconScaling,
                                    buttonScaling: _buttonScaling,
                                    surfaceOpacity: _surfaceOpacity,
                                    surfaceBlur: _surfaceBlur,
                                    cardBorderWidth: _cardBorderWidth,
                                    cardShadowIntensity: _cardShadowIntensity,
                                    buttonShadowIntensity:
                                        _buttonShadowIntensity,
                                    languageIndex: _languageIndex,
                                    secondaryColorIndex: _secondaryColorIndex,
                                    tertiaryColorIndex: _tertiaryColorIndex,
                                    backgroundColorIndex: _backgroundColorIndex,
                                    backgroundColorOpacity:
                                        _backgroundColorOpacity,
                                  );
                                }
                              : null,
                          child: Text(AppStrings.settingsSaveButton),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          style: const ButtonStyle.ghost(),
                          onPressed: hasChanges
                              ? () => setState(
                                  () => _loadDraftFrom(themeController),
                                )
                              : null,
                          child: Text(AppStrings.settingsResetButton),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );

    // Preview reflects all three draft scaling values live: `_draftTheme`
    // already carries `_widgetScaling` (via `ThemeData.scaling`), this
    // `MediaQuery` override previews `_textScaling` the same way `main.dart`
    // applies it app-wide, and the sample icon below is sized directly off
    // `_iconScaling` the same way real call sites (sidebar, KPI cards) are.
    final previewCard = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_textScaling),
      ),
      child: Theme(
      data: _draftTheme,
      child: Container(
              // A visible gutter of the *draft* page background around the
              // preview card — without this the background color/opacity
              // picker has nothing to show, since the card itself paints with
              // `colorScheme.card`, not `background`.
              color: _draftTheme.colorScheme.background,
              padding: const EdgeInsets.all(12),
              child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.settingsPreviewTitle).semiBold(),
                    const SizedBox(height: 12),
                    // Scoped `ComponentTheme<CardTheme>` override — shows the
                    // *draft* border/shadow (not yet saved) on just this one
                    // card, the same way `Theme(data: _draftTheme, ...)`
                    // above already previews the draft color/radius/etc.
                    ComponentTheme<CardTheme>(
                      data: ThemeController.buildCardTheme(
                        isDarkMode: _isDarkMode,
                        colorFamily: kColorFamilies[_colorFamilyIndex],
                        borderWidth: _cardBorderWidth,
                        shadowIntensity: _cardShadowIntensity,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppStrings.settingsPreviewSampleCardTitle)
                                  .semiBold(),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.settingsPreviewSampleCardBody,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ).muted(),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Sized directly off the draft icon-scale
                                  // value — same pattern as the real
                                  // sidebar/KPI-card call sites — so this is
                                  // a live preview of `_iconScaling`, not
                                  // just text/widget scaling.
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    size: 20 * _iconScaling,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.settingsPreviewIconLabel,
                                  ).muted().small(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Scoped `ComponentTheme` overrides — shows the
                              // *draft* button shadow (not yet saved), same
                              // pattern as the card shadow preview above.
                              ComponentTheme<PrimaryButtonTheme>(
                                data: PrimaryButtonTheme(
                                  decoration:
                                      ThemeController.buildButtonShadowDelegate(
                                        _buttonShadowIntensity,
                                      ),
                                ),
                                child: ComponentTheme<OutlineButtonTheme>(
                                  data: OutlineButtonTheme(
                                    decoration:
                                        ThemeController.buildButtonShadowDelegate(
                                          _buttonShadowIntensity,
                                        ),
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Button(
                                        style: const ButtonStyle.primary(),
                                        onPressed: () {},
                                        child: Text(
                                          AppStrings
                                              .settingsPreviewPrimaryButton,
                                        ),
                                      ),
                                      Button.outline(
                                        onPressed: () {},
                                        child: Text(
                                          AppStrings
                                              .settingsPreviewOutlineButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
      ),
    );

    // Desktop has room for controls + preview side by side. Mobile/tablet
    // don't — cramming a slider-heavy controls panel AND a preview card
    // into two ~50%-width columns on a ~390-430px phone screen is exactly
    // what was breaking the layout, so they stack instead.
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: controlsCard),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: previewCard),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controlsCard,
        const SizedBox(height: 16),
        previewCard,
      ],
    );
  }
}
