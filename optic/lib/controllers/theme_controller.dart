import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optic/constants.dart';
import 'package:optic/models/app_settings.dart';

/// Controls the entire app theme — dark/light mode, color family, corner
/// radius, UI scaling, surface opacity/blur, and typography — persisted
/// on-device via shared_preferences so it survives app restarts.
///
/// [themeData] is the single source of truth for "what does the app look
/// like right now" — `main.dart` and the Settings screen's preview both
/// just read this, instead of each computing their own ThemeData.
///
/// The persisted state itself lives in one [AppSettings] snapshot rather
/// than 9 separate fields/keys — every getter below just reads through it,
/// and every setter replaces it with `copyWith(...)` then persists the
/// whole thing at once (see `_persist`).
class ThemeController extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// The full persisted snapshot — e.g. for a future "export/reset
  /// settings" action that needs everything at once instead of one getter
  /// at a time.
  AppSettings get settings => _settings;

  bool get isDarkMode => _settings.isDarkMode;
  int get colorFamilyIndex => _settings.colorFamilyIndex;
  double get radius => _settings.radius;
  double get widgetScaling => _settings.widgetScaling;
  double get textScaling => _settings.textScaling;
  double get iconScaling => _settings.iconScaling;
  double get buttonScaling => _settings.buttonScaling;
  double get surfaceOpacity => _settings.surfaceOpacity;
  double get surfaceBlur => _settings.surfaceBlur;
  double get cardBorderWidth => _settings.cardBorderWidth;
  double get cardShadowIntensity => _settings.cardShadowIntensity;
  int get languageIndex => _settings.languageIndex;
  int get secondaryColorIndex => _settings.secondaryColorIndex;
  int get tertiaryColorIndex => _settings.tertiaryColorIndex;
  int get backgroundColorIndex => _settings.backgroundColorIndex;
  double get backgroundColorOpacity => _settings.backgroundColorOpacity;
  double get buttonShadowIntensity => _settings.buttonShadowIntensity;

  AppColorFamily get colorFamily => kColorFamilies[_settings.colorFamilyIndex];

  /// Blends [base] toward [tint] by [opacity] (0 = untouched `base`, 1 =
  /// fully `tint`). Static so the Settings preview can reuse it for the
  /// *draft* value without a second `ThemeController`.
  static Color applyColorTint(Color base, Color tint, double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    if (clamped <= 0) return base;
    return Color.lerp(base, tint, clamped)!;
  }

  /// The actual page background color — [colorFamily]'s `background` for
  /// the current dark/light mode, tinted toward
  /// `kColorFamilies[backgroundColorIndex]`'s `primary` (the same swatch
  /// color the family picker itself shows) at [backgroundColorOpacity].
  /// `-1` (the default) leaves the family's own background untouched.
  /// `AppShell`'s `Scaffold` and `Sidebar` both read this directly (rather
  /// than through [themeData]) since they already source their backdrop
  /// straight from `colorFamily` instead of `Theme.of(context)`.
  Color get backgroundColor {
    // Light mode: a fixed, slightly-off-white page backdrop (per the Aug
    // 2026 minimalist redesign) instead of whichever color family's own
    // near-white `background` — keeps a consistent, deliberate contrast
    // against white cards (see DashboardTokens) regardless of which of the
    // 8 color families is selected. Dark mode is unaffected — the color
    // families' own dark backgrounds already provide plenty of contrast.
    final base = _settings.isDarkMode
        ? colorFamily.dark.background
        : const Color(0xFFF7F8FA);
    final index = _settings.backgroundColorIndex;
    if (index < 0 || index >= kColorFamilies.length) return base;
    final family = kColorFamilies[index];
    final tint = _settings.isDarkMode ? family.dark.primary : family.light.primary;
    return applyColorTint(base, tint, _settings.backgroundColorOpacity);
  }

  /// Applies the secondary/tertiary accent overrides (if any) on top of a
  /// base color scheme — swaps in `kColorFamilies[index].<brightness>.primary`
  /// for `chart2`/`chart3`, the two slots already used app-wide as "second
  /// accent" colors (dashboard KPI icons, `kpi_row.dart`'s 3rd stat, etc.).
  /// `-1` (the default) leaves that slot untouched. Static + parameterized
  /// on `isDarkMode` so the Settings preview can reuse it for the *draft*
  /// scheme without needing a second `ThemeController`.
  static ColorScheme applyAccentOverrides(
    ColorScheme base, {
    required bool isDarkMode,
    required int secondaryColorIndex,
    required int tertiaryColorIndex,
  }) {
    var scheme = base;
    if (secondaryColorIndex >= 0 && secondaryColorIndex < kColorFamilies.length) {
      final family = kColorFamilies[secondaryColorIndex];
      final accent = isDarkMode ? family.dark.primary : family.light.primary;
      scheme = scheme.copyWith(chart2: () => accent);
    }
    if (tertiaryColorIndex >= 0 && tertiaryColorIndex < kColorFamilies.length) {
      final family = kColorFamilies[tertiaryColorIndex];
      final accent = isDarkMode ? family.dark.primary : family.light.primary;
      scheme = scheme.copyWith(chart3: () => accent);
    }
    return scheme;
  }

  /// The currently selected UI language — code, display name, and text
  /// direction. See [AppLanguage] for what this does (and doesn't) drive.
  AppLanguage get language => kLanguages[_settings.languageIndex];

  /// True when [language] reads right-to-left (Arabic) — used to flip
  /// `Directionality` app-wide in `main.dart`.
  bool get isRtl => language.isRtl;

  ThemeData get themeData {
    final base = _settings.isDarkMode ? colorFamily.dark : colorFamily.light;
    var scheme = applyAccentOverrides(
      base,
      isDarkMode: _settings.isDarkMode,
      secondaryColorIndex: _settings.secondaryColorIndex,
      tertiaryColorIndex: _settings.tertiaryColorIndex,
    );
    scheme = scheme.copyWith(background: () => backgroundColor);
    // Geist is always the app's typography now (no longer a toggle).
    return ThemeData(
      colorScheme: scheme,
      radius: _settings.radius,
      scaling: _settings.widgetScaling,
      surfaceOpacity: _settings.surfaceOpacity,
      surfaceBlur: _settings.surfaceBlur,
      typography: const Typography.geist(),
    );
  }

  /// The current card border/shadow, applied app-wide via
  /// `ComponentTheme<CardTheme>` in `main.dart`'s `ShadcnApp.router(builder:
  /// ...)`. This is what actually separates cards from the page background —
  /// `ColorScheme.card` alone was too close to `ColorScheme.background` to
  /// read as a distinct surface.
  CardTheme get cardTheme => buildCardTheme(
    isDarkMode: _settings.isDarkMode,
    colorFamily: colorFamily,
    borderWidth: _settings.cardBorderWidth,
    shadowIntensity: _settings.cardShadowIntensity,
  );

  /// Pure builder behind [cardTheme] — pulled out as a static function so
  /// the Settings preview can compute the *draft* card style (before it's
  /// applied/persisted) without needing a second `ThemeController` instance.
  static CardTheme buildCardTheme({
    required bool isDarkMode,
    required AppColorFamily colorFamily,
    required double borderWidth,
    required double shadowIntensity,
  }) {
    final scheme = isDarkMode ? colorFamily.dark : colorFamily.light;
    final hasBorder = borderWidth > 0;
    final hasShadow = shadowIntensity > 0;
    return CardTheme(
      borderWidth: hasBorder ? borderWidth : null,
      borderColor: hasBorder ? scheme.border : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.28 * shadowIntensity),
                blurRadius: 18 * shadowIntensity,
                offset: Offset(0, 3 + 3 * shadowIntensity),
              ),
            ]
          : null,
    );
  }

  /// The 5 button-family theme overrides, applied via
  /// `ComponentTheme<PrimaryButtonTheme>` etc. — scoped inside `AppShell`'s
  /// screen-content area only (not the sidebar), see `app_shell.dart`. Each
  /// rebuilds its shadow delegate from the current [buttonShadowIntensity]
  /// so the Settings slider takes effect live, same pattern as [cardTheme].
  PrimaryButtonTheme get primaryButtonTheme => PrimaryButtonTheme(
    decoration: buildButtonShadowDelegate(_settings.buttonShadowIntensity),
  );
  OutlineButtonTheme get outlineButtonTheme => OutlineButtonTheme(
    decoration: buildButtonShadowDelegate(_settings.buttonShadowIntensity),
  );
  GhostButtonTheme get ghostButtonTheme => GhostButtonTheme(
    decoration: buildButtonShadowDelegate(_settings.buttonShadowIntensity),
  );
  LinkButtonTheme get linkButtonTheme => LinkButtonTheme(
    decoration: buildButtonShadowDelegate(_settings.buttonShadowIntensity),
  );
  DestructiveButtonTheme get destructiveButtonTheme => DestructiveButtonTheme(
    decoration: buildButtonShadowDelegate(_settings.buttonShadowIntensity),
  );

  /// Pure builder behind the 5 getters above — pulled out as a static
  /// function so the Settings preview can compute the *draft* shadow (before
  /// it's applied/persisted) without needing a second `ThemeController`
  /// instance, same as [buildCardTheme].
  ///
  /// [intensity] (0..1) scales both blur radius and opacity — kept tight/
  /// crisp by design (small blur radii) rather than soft, since a large blur
  /// was the "too blurry" complaint that prompted making this adjustable.
  /// `0` returns the untouched default decoration (no shadow at all) instead
  /// of a near-invisible one.
  static ButtonStatePropertyDelegate<Decoration> buildButtonShadowDelegate(
    double intensity,
  ) {
    return (BuildContext context, Set<WidgetState> states, Decoration defaultValue) {
      if (defaultValue is! BoxDecoration) return defaultValue;
      if (intensity <= 0) return defaultValue;
      final hovered = states.contains(WidgetState.hovered);
      return defaultValue.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              (hovered ? 0.14 : 0.08) + 0.16 * intensity,
            ),
            blurRadius: (hovered ? 2 : 1) + 3 * intensity,
            offset: Offset(0, 1 + 0.5 * intensity),
          ),
        ],
      );
    };
  }

  ThemeController() {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ThemePrefsKeys.settings);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
      } catch (_) {
        // Corrupt or old-shape value (e.g. from before this was bundled
        // into one key) — fall back to defaults rather than crash.
        _settings = AppSettings.defaults();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ThemePrefsKeys.settings,
      jsonEncode(_settings.toJson()),
    );
  }

  /// Applies every field at once — one `notifyListeners()`, one persisted
  /// write — used by Settings' Save button so staged/draft changes commit
  /// together instead of one at a time.
  Future<void> applyTheme({
    required bool isDarkMode,
    required int colorFamilyIndex,
    required double radius,
    required double widgetScaling,
    required double textScaling,
    required double iconScaling,
    required double buttonScaling,
    required double surfaceOpacity,
    required double surfaceBlur,
    required double cardBorderWidth,
    required double cardShadowIntensity,
    required int languageIndex,
    required int secondaryColorIndex,
    required int tertiaryColorIndex,
    required int backgroundColorIndex,
    required double backgroundColorOpacity,
    required double buttonShadowIntensity,
  }) async {
    _settings = AppSettings(
      isDarkMode: isDarkMode,
      colorFamilyIndex: colorFamilyIndex,
      radius: radius,
      widgetScaling: widgetScaling,
      textScaling: textScaling,
      iconScaling: iconScaling,
      buttonScaling: buttonScaling,
      surfaceOpacity: surfaceOpacity,
      surfaceBlur: surfaceBlur,
      cardBorderWidth: cardBorderWidth,
      cardShadowIntensity: cardShadowIntensity,
      languageIndex: languageIndex,
      secondaryColorIndex: secondaryColorIndex,
      tertiaryColorIndex: tertiaryColorIndex,
      backgroundColorIndex: backgroundColorIndex,
      backgroundColorOpacity: backgroundColorOpacity,
      buttonShadowIntensity: buttonShadowIntensity,
    );
    notifyListeners();
    await _persist();
  }

  /// Toggle between dark and light mode
  void toggleTheme() => setTheme(!_settings.isDarkMode);

  /// Explicitly set theme mode
  void setTheme(bool darkMode) {
    _settings = _settings.copyWith(isDarkMode: darkMode);
    notifyListeners();
    _persist();
  }

  void setColorFamilyIndex(int index) {
    _settings = _settings.copyWith(colorFamilyIndex: index);
    notifyListeners();
    _persist();
  }

  void setRadius(double value) {
    _settings = _settings.copyWith(radius: value);
    notifyListeners();
    _persist();
  }

  void setWidgetScaling(double value) {
    _settings = _settings.copyWith(widgetScaling: value);
    notifyListeners();
    _persist();
  }

  void setTextScaling(double value) {
    _settings = _settings.copyWith(textScaling: value);
    notifyListeners();
    _persist();
  }

  void setIconScaling(double value) {
    _settings = _settings.copyWith(iconScaling: value);
    notifyListeners();
    _persist();
  }

  void setButtonScaling(double value) {
    _settings = _settings.copyWith(buttonScaling: value);
    notifyListeners();
    _persist();
  }

  void setSurfaceOpacity(double value) {
    _settings = _settings.copyWith(surfaceOpacity: value);
    notifyListeners();
    _persist();
  }

  void setSurfaceBlur(double value) {
    _settings = _settings.copyWith(surfaceBlur: value);
    notifyListeners();
    _persist();
  }

  void setCardBorderWidth(double value) {
    _settings = _settings.copyWith(cardBorderWidth: value);
    notifyListeners();
    _persist();
  }

  void setCardShadowIntensity(double value) {
    _settings = _settings.copyWith(cardShadowIntensity: value);
    notifyListeners();
    _persist();
  }

  void setLanguageIndex(int index) {
    _settings = _settings.copyWith(languageIndex: index);
    notifyListeners();
    _persist();
  }

  void setSecondaryColorIndex(int index) {
    _settings = _settings.copyWith(secondaryColorIndex: index);
    notifyListeners();
    _persist();
  }

  void setTertiaryColorIndex(int index) {
    _settings = _settings.copyWith(tertiaryColorIndex: index);
    notifyListeners();
    _persist();
  }

  void setBackgroundColorIndex(int index) {
    _settings = _settings.copyWith(backgroundColorIndex: index);
    notifyListeners();
    _persist();
  }

  void setBackgroundColorOpacity(double value) {
    _settings = _settings.copyWith(backgroundColorOpacity: value);
    notifyListeners();
    _persist();
  }

  void setButtonShadowIntensity(double value) {
    _settings = _settings.copyWith(buttonShadowIntensity: value);
    notifyListeners();
    _persist();
  }
}
