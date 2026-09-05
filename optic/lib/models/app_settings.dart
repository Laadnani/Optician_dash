import 'package:optic/constants.dart';

/// One immutable snapshot of every theme/appearance setting
/// [ThemeController] owns — dark/light mode, color family, corner radius,
/// UI scaling, surface opacity/blur, typography, and card border/shadow.
///
/// This bundles what used to be 9 separate shared_preferences keys into a
/// single persisted value (JSON-encoded, see `ThemePrefsKeys.settings`), so
/// the whole theme loads and saves as one unit — no risk of ending up with
/// some fields from an old save and some from a new one.
class AppSettings {
  final bool isDarkMode;
  final int colorFamilyIndex;
  final double radius;
  // Split from one `scaling` field into three — see `ThemeDefaults` in
  // constants.dart for what each one drives.
  final double widgetScaling;
  final double textScaling;
  final double iconScaling;
  final double buttonScaling;
  final double surfaceOpacity;
  final double surfaceBlur;
  final double cardBorderWidth;
  final double cardShadowIntensity;
  final int languageIndex;
  final int secondaryColorIndex;
  final int tertiaryColorIndex;
  final int backgroundColorIndex;
  final double backgroundColorOpacity;
  final double buttonShadowIntensity;

  const AppSettings({
    required this.isDarkMode,
    required this.colorFamilyIndex,
    required this.radius,
    required this.widgetScaling,
    required this.textScaling,
    required this.iconScaling,
    required this.buttonScaling,
    required this.surfaceOpacity,
    required this.surfaceBlur,
    required this.cardBorderWidth,
    required this.cardShadowIntensity,
    required this.languageIndex,
    required this.secondaryColorIndex,
    required this.tertiaryColorIndex,
    required this.backgroundColorIndex,
    required this.backgroundColorOpacity,
    required this.buttonShadowIntensity,
  });

  /// What a fresh install (or a corrupt/missing persisted value) falls back
  /// to — mirrors `ThemeDefaults` field-for-field.
  factory AppSettings.defaults() => const AppSettings(
    isDarkMode: ThemeDefaults.isDarkMode,
    colorFamilyIndex: ThemeDefaults.colorFamilyIndex,
    radius: ThemeDefaults.radius,
    widgetScaling: ThemeDefaults.widgetScaling,
    textScaling: ThemeDefaults.textScaling,
    iconScaling: ThemeDefaults.iconScaling,
    buttonScaling: ThemeDefaults.buttonScaling,
    surfaceOpacity: ThemeDefaults.surfaceOpacity,
    surfaceBlur: ThemeDefaults.surfaceBlur,
    cardBorderWidth: ThemeDefaults.cardBorderWidth,
    cardShadowIntensity: ThemeDefaults.cardShadowIntensity,
    languageIndex: ThemeDefaults.languageIndex,
    secondaryColorIndex: ThemeDefaults.secondaryColorIndex,
    tertiaryColorIndex: ThemeDefaults.tertiaryColorIndex,
    backgroundColorIndex: ThemeDefaults.backgroundColorIndex,
    backgroundColorOpacity: ThemeDefaults.backgroundColorOpacity,
    buttonShadowIntensity: ThemeDefaults.buttonShadowIntensity,
  );

  AppSettings copyWith({
    bool? isDarkMode,
    int? colorFamilyIndex,
    double? radius,
    double? widgetScaling,
    double? textScaling,
    double? iconScaling,
    double? buttonScaling,
    double? surfaceOpacity,
    double? surfaceBlur,
    double? cardBorderWidth,
    double? cardShadowIntensity,
    int? languageIndex,
    int? secondaryColorIndex,
    int? tertiaryColorIndex,
    int? backgroundColorIndex,
    double? backgroundColorOpacity,
    double? buttonShadowIntensity,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      colorFamilyIndex: colorFamilyIndex ?? this.colorFamilyIndex,
      radius: radius ?? this.radius,
      widgetScaling: widgetScaling ?? this.widgetScaling,
      textScaling: textScaling ?? this.textScaling,
      iconScaling: iconScaling ?? this.iconScaling,
      buttonScaling: buttonScaling ?? this.buttonScaling,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
      cardShadowIntensity: cardShadowIntensity ?? this.cardShadowIntensity,
      languageIndex: languageIndex ?? this.languageIndex,
      secondaryColorIndex: secondaryColorIndex ?? this.secondaryColorIndex,
      tertiaryColorIndex: tertiaryColorIndex ?? this.tertiaryColorIndex,
      backgroundColorIndex: backgroundColorIndex ?? this.backgroundColorIndex,
      backgroundColorOpacity:
          backgroundColorOpacity ?? this.backgroundColorOpacity,
      buttonShadowIntensity:
          buttonShadowIntensity ?? this.buttonShadowIntensity,
    );
  }

  /// Tolerant of missing/malformed keys — anything absent falls back to
  /// `ThemeDefaults`, so a partially-written or older-shaped JSON blob still
  /// loads instead of crashing.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) => (v as num?)?.toDouble();
    // Older persisted blobs only have a single 'scaling' key (before this
    // was split three ways) — treat that as the widget-scaling value so
    // existing users don't lose their chosen scale on upgrade, and leave
    // text/icon scaling at their fresh-install defaults.
    final legacyScaling = asDouble(json['scaling']);
    return AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? ThemeDefaults.isDarkMode,
      colorFamilyIndex:
          json['colorFamilyIndex'] as int? ?? ThemeDefaults.colorFamilyIndex,
      radius: asDouble(json['radius']) ?? ThemeDefaults.radius,
      widgetScaling:
          asDouble(json['widgetScaling']) ??
          legacyScaling ??
          ThemeDefaults.widgetScaling,
      textScaling: asDouble(json['textScaling']) ?? ThemeDefaults.textScaling,
      iconScaling: asDouble(json['iconScaling']) ?? ThemeDefaults.iconScaling,
      buttonScaling:
          asDouble(json['buttonScaling']) ?? ThemeDefaults.buttonScaling,
      surfaceOpacity:
          asDouble(json['surfaceOpacity']) ?? ThemeDefaults.surfaceOpacity,
      surfaceBlur: asDouble(json['surfaceBlur']) ?? ThemeDefaults.surfaceBlur,
      cardBorderWidth:
          asDouble(json['cardBorderWidth']) ?? ThemeDefaults.cardBorderWidth,
      cardShadowIntensity:
          asDouble(json['cardShadowIntensity']) ??
          ThemeDefaults.cardShadowIntensity,
      languageIndex: json['languageIndex'] as int? ?? ThemeDefaults.languageIndex,
      secondaryColorIndex:
          json['secondaryColorIndex'] as int? ??
          ThemeDefaults.secondaryColorIndex,
      tertiaryColorIndex:
          json['tertiaryColorIndex'] as int? ??
          ThemeDefaults.tertiaryColorIndex,
      backgroundColorIndex:
          json['backgroundColorIndex'] as int? ??
          ThemeDefaults.backgroundColorIndex,
      backgroundColorOpacity:
          asDouble(json['backgroundColorOpacity']) ??
          ThemeDefaults.backgroundColorOpacity,
      buttonShadowIntensity:
          asDouble(json['buttonShadowIntensity']) ??
          ThemeDefaults.buttonShadowIntensity,
    );
  }

  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'colorFamilyIndex': colorFamilyIndex,
    'radius': radius,
    'widgetScaling': widgetScaling,
    'textScaling': textScaling,
    'iconScaling': iconScaling,
    'buttonScaling': buttonScaling,
    'surfaceOpacity': surfaceOpacity,
    'surfaceBlur': surfaceBlur,
    'cardBorderWidth': cardBorderWidth,
    'cardShadowIntensity': cardShadowIntensity,
    'languageIndex': languageIndex,
    'secondaryColorIndex': secondaryColorIndex,
    'tertiaryColorIndex': tertiaryColorIndex,
    'backgroundColorIndex': backgroundColorIndex,
    'backgroundColorOpacity': backgroundColorOpacity,
    'buttonShadowIntensity': buttonShadowIntensity,
  };
}
