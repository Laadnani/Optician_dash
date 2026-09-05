// lib/constants.dart
import 'package:shadcn_flutter/shadcn_flutter.dart';

// You can also define other constants here (padding, default duration, etc.)
const double defaultPadding = 16.0;

// NOTE: this file used to also define bgColor/secondaryColor/accentColor/
// secondaryBorderColor as hardcoded blue constants for card borders — they
// were never wired into any widget, and being hardcoded they'd only have
// looked right for the "Blue" color family anyway. Card border/shadow is
// now driven by ThemeController.cardTheme instead, which derives its color
// from whichever color family is actually selected (see below).

// ---------------------------------------------------------------------------
// Theme — color families, defaults, and shared_preferences keys.
// Everything ThemeController reads/writes lives here rather than in its own
// file, since this file is meant to hold all shared-prefs-backed constants,
// not just theme ones.
// ---------------------------------------------------------------------------

/// A named color family — one `light`/`dark` pair. The 7 real hue families
/// live on shadcn_flutter's `LegacyColorSchemes` class (confirmed against
/// the pinned v0.0.39 source — `lib/src/theme/legacy_generated_themes.dart`)
/// as METHODS (`lightBlue()`, not a `lightBlue` getter) — the plain
/// `ColorSchemes` class only exposes 5 neutral bases (gray/neutral/slate/
/// stone/zinc), nothing hue-named. "Default" isn't a real shadcn_flutter
/// family under any name, so it's mapped to Zinc here — shadcn/ui's actual
/// literal default palette — rather than left broken; flag if you wanted
/// something else for that slot.
class AppColorFamily {
  final String name;
  final ColorScheme light;
  final ColorScheme dark;
  const AppColorFamily(this.name, this.light, this.dark);
}

List<AppColorFamily> kColorFamilies = [
  AppColorFamily(
    'Default',
    LegacyColorSchemes.lightZinc(),
    LegacyColorSchemes.darkZinc(),
  ),
  AppColorFamily(
    'Blue',
    LegacyColorSchemes.lightBlue(),
    LegacyColorSchemes.darkBlue(),
  ),
  AppColorFamily(
    'Green',
    LegacyColorSchemes.lightGreen(),
    LegacyColorSchemes.darkGreen(),
  ),
  AppColorFamily(
    'Orange',
    LegacyColorSchemes.lightOrange(),
    LegacyColorSchemes.darkOrange(),
  ),
  AppColorFamily(
    'Red',
    LegacyColorSchemes.lightRed(),
    LegacyColorSchemes.darkRed(),
  ),
  AppColorFamily(
    'Rose',
    LegacyColorSchemes.lightRose(),
    LegacyColorSchemes.darkRose(),
  ),
  AppColorFamily(
    'Violet',
    LegacyColorSchemes.lightViolet(),
    LegacyColorSchemes.darkViolet(),
  ),
  AppColorFamily(
    'Yellow',
    LegacyColorSchemes.lightYellow(),
    LegacyColorSchemes.darkYellow(),
  ),
];

/// A supported UI language — ISO code, the name as shown *in that
/// language* (so a French speaker sees "Français", not "French"), and
/// whether it reads right-to-left.
///
/// Note: this only drives the language *setting* (persisted choice +
/// text direction). Translating every string in `AppStrings` into each
/// language is the follow-up described in that file's own doc comment.
class AppLanguage {
  final String code;
  final String name;
  final bool isRtl;
  const AppLanguage(this.code, this.name, {this.isRtl = false});
}

const List<AppLanguage> kLanguages = [
  AppLanguage('en', 'English'),
  AppLanguage('fr', 'Français'),
  AppLanguage('ar', 'العربية', isRtl: true),
];

/// Default values used the very first time the app runs, before anything
/// has been persisted yet.
class ThemeDefaults {
  ThemeDefaults._();

  // Redesign (Aug 2026, per designer brief): a modern SaaS/healthcare-ops
  // look — soft neutral light background, white/very-light cards, one
  // strong primary accent (Blue) — rather than the dark shell this used to
  // default to.
  static const bool isDarkMode = false;
  static const int colorFamilyIndex = 1; // 'Blue' — the one strong accent
  static const int languageIndex = 0; // 'English' — index into kLanguages
  static const double radius = 1.5;
  // Split from a single "UI scale" into three independent knobs: widget
  // scaling (spacing/sizing via ThemeData.scaling — unchanged behavior),
  // text scaling (drives MediaQuery.textScaler app-wide), and icon scaling
  // (a manual multiplier applied at Icon() call sites, since most icons in
  // this codebase pass an explicit `size:` that a theme-level icon size
  // would never reach anyway).
  static const double widgetScaling = 1.0;
  static const double textScaling = 1.0;
  static const double iconScaling = 1.0;
  // A 4th independent knob split off `widgetScaling`: the hand-built
  // "+ New" quick-action button in `AppTopBar` (the one custom button in
  // the app that isn't a real shadcn `Button`/`PrimaryButton`, so it never
  // picked up `ThemeData.scaling`) reads this directly to size its own
  // padding/icon/text. Every other button already scales via
  // `widgetScaling` and is unaffected by this field.
  static const double buttonScaling = 1.0;
  static const double surfaceOpacity = 0.8;
  static const double surfaceBlur = 8.0;

  // Card border width in logical pixels — 0 disables the border entirely.
  // 1.0 is a deliberately visible-but-subtle default, tuned to separate
  // cards from the page background without looking boxy.
  static const double cardBorderWidth = 1.0;

  // Card shadow strength, 0 (off) to 1 (strongest). Scales both the shadow's
  // opacity and blur radius — see ThemeController.buildCardTheme. Zeroed
  // out per the Aug 2026 "minimalist" dashboard redesign: surface contrast
  // (page background vs. white cards) + the 1px border above are what
  // separate cards from the page now, not a floating shadow.
  static const double cardShadowIntensity = 0.0;

  // Secondary/tertiary accent overrides — index into `kColorFamilies`
  // (reusing the same 8 named swatches the primary color picker already
  // offers) applied on top of whichever family is selected, replacing just
  // `ColorScheme.chart2`/`chart3` (the two slots already used app-wide for
  // "second accent" KPI icons and chart series — see `dashboard_widgets.dart`,
  // `kpi_row.dart`). `-1` means "no override, inherit chart2/chart3 from the
  // selected family" — the default, so this ships with zero visual change
  // until a user opts in from Settings.
  static const int secondaryColorIndex = -1;
  static const int tertiaryColorIndex = -1;

  // Background tint — index into `kColorFamilies` (reusing the same 8
  // swatches as the primary/secondary/tertiary pickers) blended over the
  // page background at `backgroundColorOpacity`. `-1` (the default) means
  // no tint at all — the family's own background, untouched. See
  // `ThemeController.backgroundColor`.
  //
  // A prior version of this setting was a plain grayscale slider, but the
  // light theme's own background is already near-neutral (very light
  // gray/white), so desaturating it further was invisible — a chosen hue
  // blended in at an adjustable opacity actually shows up.
  static const int backgroundColorIndex = -1;
  static const double backgroundColorOpacity = 0.15;

  // Button drop-shadow strength, 0 (off) to 1 (strongest) — scales both the
  // shadow's blur radius and opacity, see
  // `ThemeController.buildButtonShadowDelegate`. Kept deliberately tight/crisp
  // rather than soft — a low default blur radius that reads as "raised",
  // not "hazy". Adjustable from Settings for anyone who wants it stronger,
  // softer, or off entirely.
  static const double buttonShadowIntensity = 0.35;
}

/// Fixed visual tokens for the redesigned dashboard (Aug 2026 "minimalist
/// operational center" pass) — deliberately NOT part of [ThemeController]/
/// [AppSettings]: these are layout constants (radii, paddings, gaps), not
/// user-adjustable theme knobs. Every dashboard-specific widget (KPI tiles,
/// the Attention section, the Tasks/Appointments/Sales/Activity/Inventory
/// panels) reads these instead of hardcoding its own numbers, so the whole
/// dashboard shares one visual language and a future tweak only has to
/// happen in one place.
class DashboardTokens {
  DashboardTokens._();

  /// Large panels — KPI cards, task/appointment panels, chart cards,
  /// inventory panel.
  static const double radius = 16;

  /// Small elements — badges, status dots' containers, filter chips, tiny
  /// buttons.
  static const double smallRadius = 10;

  static const double pagePadding = 24;
  static const double cardPadding = 20;
  static const double sectionGap = 24;
  static const double itemGap = 12;
  static const double borderWidth = 1;
}

/// shared_preferences key(s) for everything ThemeController persists.
///
/// One JSON-encoded blob (see `AppSettings`/`ThemeController._persist`)
/// rather than one key per field — the whole theme snapshot loads and
/// saves as a single unit, so it can't end up half-written.
class ThemePrefsKeys {
  ThemePrefsKeys._();

  static const String settings = 'theme.settings';
}

/// shared_preferences key(s) for [DashboardPrefsController] — which
/// dashboard widgets are currently switched on.
class DashboardPrefsKeys {
  DashboardPrefsKeys._();

  static const String enabledWidgets = 'dashboard.enabledWidgets';
}