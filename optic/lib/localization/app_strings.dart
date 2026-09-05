import 'package:optic/localization/app_translations.dart';

/// Every user-facing piece of text used across the dashboard, sidebar, and
/// their widgets, in one place.
///
/// Each field is a lookup into [kTranslations] for whichever language is
/// currently active (see [setLanguage]) — callers use these exactly like
/// they always have (`AppStrings.navDashboard`, etc.); only this file
/// (plus `app_translations.dart`) knows translations exist at all.
///
/// [setLanguage] is called from `main.dart` every time `ThemeController`'s
/// persisted language changes, so switching languages in Settings updates
/// every screen on the next rebuild — no per-widget wiring needed.
class AppStrings {
  AppStrings._();

  static String _languageCode = 'en';

  /// Switches every getter below to [code]'s translations. Falls back to
  /// English for an unrecognized code rather than throwing.
  static void setLanguage(String code) {
    _languageCode = kTranslations.containsKey(code) ? code : 'en';
  }

  /// Current lookup — 100% of the translated strings' language, but also
  /// what [clientsCount] uses for its own plural rules.
  static String get currentLanguageCode => _languageCode;

  /// Looks [key] up in the active language, falling back to English for a
  /// key that hasn't been translated yet (or is simply missing), and to
  /// the literal key itself if even English is somehow missing it — so a
  /// typo'd key shows up as an obviously-wrong string instead of crashing.
  static String _t(String key) =>
      kTranslations[_languageCode]?[key] ??
      kTranslations['en']?[key] ??
      key;

  // --- Sidebar / nav -----------------------------------------------------
  static String get navDashboard => _t('navDashboard');
  static String get navBilling => _t('navBilling');
  static String get navClients => _t('navClients');
  static String get navCalendar => _t('navCalendar');
  static String get navTasks => _t('navTasks');
  static String get navSettings => _t('navSettings');
  static String get sidebarSignOut => _t('sidebarSignOut');

  // --- Sidebar: section group headers (grouping the placeholder modules ---
  // below into the spec's 8-module architecture) -----------------------------
  static String get navSectionClients => _t('navSectionClients');
  static String get navSectionOpticalConsultation =>
      _t('navSectionOpticalConsultation');
  static String get navSectionProductsInventory =>
      _t('navSectionProductsInventory');
  static String get navSectionSales => _t('navSectionSales');
  static String get navSectionProduction => _t('navSectionProduction');
  static String get navSectionClientDelivery =>
      _t('navSectionClientDelivery');
  static String get navSectionProcurement => _t('navSectionProcurement');
  static String get navSectionManagement => _t('navSectionManagement');

  // --- Sidebar: new placeholder module destinations (optical-retail -------
  // architecture spec — screens land on these one module at a time) --------
  static String get navConsultation => _t('navConsultation');
  static String get navPrescriptions => _t('navPrescriptions');
  static String get navMeasurements => _t('navMeasurements');
  static String get navCommunication => _t('navCommunication');
  static String get navFrameSelection => _t('navFrameSelection');
  static String get navLensRecommendation => _t('navLensRecommendation');
  static String get navFrameInventory => _t('navFrameInventory');
  static String get navLensCatalog => _t('navLensCatalog');
  static String get navContactLenses => _t('navContactLenses');
  static String get navAccessories => _t('navAccessories');
  static String get navQuotes => _t('navQuotes');
  static String get navOrders => _t('navOrders');
  static String get navLaboratory => _t('navLaboratory');
  static String get navMounting => _t('navMounting');
  static String get navQualityControl => _t('navQualityControl');
  static String get navFinalFitting => _t('navFinalFitting');
  static String get navDelivery => _t('navDelivery');
  static String get navAfterSales => _t('navAfterSales');
  static String get navRepairs => _t('navRepairs');
  static String get navWarranty => _t('navWarranty');
  static String get navSuppliers => _t('navSuppliers');
  static String get navPurchasing => _t('navPurchasing');

  // --- Quick actions -------------------------------------------------------
  static String get quickActionNewAppointment =>
      _t('quickActionNewAppointment');
  static String get quickActionNewClient => _t('quickActionNewClient');

  // --- KPI row -------------------------------------------------------------
  static String get kpiTodaysAppointments => _t('kpiTodaysAppointments');
  static String get kpiCompleted => _t('kpiCompleted');
  static String get kpiScheduled => _t('kpiScheduled');
  static String get kpiCancelled => _t('kpiCancelled');

  // --- Pending tasks panel --------------------------------------------------
  static String get pendingTasksTitle => _t('pendingTasksTitle');

  // --- Appointment tile: status labels ---------------------------------------
  // Matches the exact 3 values your real Appointment.status uses.
  static String get statusScheduled => _t('statusScheduled');
  static String get statusCompleted => _t('statusCompleted');
  static String get statusCancelled => _t('statusCancelled');
  static String get statusPending => _t('statusPending');
  static String get statusPaid => _t('statusPaid');

  // --- Appointment tile: action buttons --------------------------------------
  static String get actionStart => _t('actionStart');
  static String get actionChart => _t('actionChart');

  // --- Placeholder screen ---------------------------------------------------
  static String get placeholderComingSoon => _t('placeholderComingSoon');

  // --- Settings screen -------------------------------------------------------
  static String get settingsAppearanceTab => _t('settingsAppearanceTab');
  static String get settingsAccountTab => _t('settingsAccountTab');
  static String get settingsNotificationsTab =>
      _t('settingsNotificationsTab');
  static String get settingsAccountIntro => _t('settingsAccountIntro');
  static String get settingsAccountEmailLabel =>
      _t('settingsAccountEmailLabel');
  static String get settingsAccountBusinessNameLabel =>
      _t('settingsAccountBusinessNameLabel');
  static String get settingsAccountOwnerNameLabel =>
      _t('settingsAccountOwnerNameLabel');
  static String get settingsAccountPhoneLabel =>
      _t('settingsAccountPhoneLabel');
  static String get settingsAccountSubscriptionLabel =>
      _t('settingsAccountSubscriptionLabel');
  static String get settingsAccountValueNotSet =>
      _t('settingsAccountValueNotSet');
  static String get settingsAccountPhotoLabel =>
      _t('settingsAccountPhotoLabel');
  static String get settingsAccountPhotoChangeButton =>
      _t('settingsAccountPhotoChangeButton');
  static String get settingsAccountPhotoSuccess =>
      _t('settingsAccountPhotoSuccess');
  static String get settingsAccountPhotoError =>
      _t('settingsAccountPhotoError');
  static String get settingsAccountPhotoTooLarge =>
      _t('settingsAccountPhotoTooLarge');
  static String get settingsColorSchemeLabel =>
      _t('settingsColorSchemeLabel');
  static String get settingsLanguageLabel => _t('settingsLanguageLabel');
  static String get settingsDarkModeLabel => _t('settingsDarkModeLabel');
  static String get settingsRadiusLabel => _t('settingsRadiusLabel');
  static String get settingsWidgetScalingLabel =>
      _t('settingsWidgetScalingLabel');
  static String get settingsTextScalingLabel => _t('settingsTextScalingLabel');
  static String get settingsIconScalingLabel => _t('settingsIconScalingLabel');
  static String get settingsSurfaceOpacityLabel =>
      _t('settingsSurfaceOpacityLabel');
  static String get settingsSurfaceBlurLabel =>
      _t('settingsSurfaceBlurLabel');
  static String get settingsCardBorderLabel => _t('settingsCardBorderLabel');
  static String get settingsCardShadowLabel =>
      _t('settingsCardShadowLabel');
  static String get settingsButtonShadowLabel =>
      _t('settingsButtonShadowLabel');
  static String get settingsBackgroundColorLabel =>
      _t('settingsBackgroundColorLabel');
  static String get settingsBackgroundOpacityLabel =>
      _t('settingsBackgroundOpacityLabel');
  static String get settingsBackgroundColorDefaultOption =>
      _t('settingsBackgroundColorDefaultOption');
  static String get settingsPreviewTitle => _t('settingsPreviewTitle');
  static String get settingsSaveButton => _t('settingsSaveButton');
  static String get settingsResetButton => _t('settingsResetButton');
  static String get settingsUnsavedChangesNote =>
      _t('settingsUnsavedChangesNote');

  // --- Clients screen -------------------------------------------------------
  static String get clientsSearchPlaceholder =>
      _t('clientsSearchPlaceholder');
  static String get clientsAddButton => _t('clientsAddButton');
  static String get clientsEmptyTitle => _t('clientsEmptyTitle');
  static String get clientsEmptySubtitle => _t('clientsEmptySubtitle');
  static String get clientsNoResultsTitle => _t('clientsNoResultsTitle');
  static String get clientsNoResultsSubtitle =>
      _t('clientsNoResultsSubtitle');

  /// Locale-aware plural, not just a lookup — French treats 0 as singular
  /// same as 1, and Arabic has distinct singular/dual/plural-3-10/plural-11+
  /// forms, so this can't be a flat key/value pair like the rest.
  static String clientsCount(int count) {
    switch (_languageCode) {
      case 'fr':
        return count <= 1 ? '$count client' : '$count clients';
      case 'ar':
        if (count == 0) return 'لا يوجد عملاء';
        if (count == 1) return 'عميل واحد';
        if (count == 2) return 'عميلان';
        if (count >= 3 && count <= 10) return '$count عملاء';
        return '$count عميلًا';
      default:
        return count == 1 ? '1 client' : '$count clients';
    }
  }

  // --- Add client screen -----------------------------------------------------
  static String get addClientTitle => _t('addClientTitle');
  static String get addClientPageSubtitle => _t('addClientPageSubtitle');
  static String get addClientFirstName => _t('addClientFirstName');
  static String get addClientLastName => _t('addClientLastName');
  static String get addClientDob => _t('addClientDob');
  static String get addClientDobHint => _t('addClientDobHint');
  static String get addClientDobError => _t('addClientDobError');
  static String get addClientGender => _t('addClientGender');
  static String get addClientGenderMale => _t('addClientGenderMale');
  static String get addClientGenderFemale => _t('addClientGenderFemale');
  static String get addClientGenderOther => _t('addClientGenderOther');
  static String get addClientBloodGroup => _t('addClientBloodGroup');
  static String get addClientPhone => _t('addClientPhone');
  static String get addClientEmail => _t('addClientEmail');
  static String get addClientNationalId => _t('addClientNationalId');
  static String get addClientInsurance => _t('addClientInsurance');
  static String get addClientCancel => _t('addClientCancel');
  static String get addClientSubmit => _t('addClientSubmit');
  static String get editClientTitle => _t('editClientTitle');
  static String get editClientPageSubtitle => _t('editClientPageSubtitle');
  static String get editClientSubmit => _t('editClientSubmit');
  static String get clientFileEdit => _t('clientFileEdit');
  static String get clientFileNextAppointment => _t('clientFileNextAppointment');
  static String get clientFileNoUpcomingAppointment => _t('clientFileNoUpcomingAppointment');
  static String get clientFileLatestPrescription => _t('clientFileLatestPrescription');
  static String get clientFileViewFullPrescription => _t('clientFileViewFullPrescription');
  static String get clientFileNoPrescriptionYet => _t('clientFileNoPrescriptionYet');
  static String get prescriptionColSphere => _t('prescriptionColSphere');
  static String get prescriptionColCylinder => _t('prescriptionColCylinder');
  static String get prescriptionColAxis => _t('prescriptionColAxis');
  static String get prescriptionColAdd => _t('prescriptionColAdd');
  static String get prescriptionColRightEye => _t('prescriptionColRightEye');
  static String get prescriptionColLeftEye => _t('prescriptionColLeftEye');
  static String get addClientAddress => _t('addClientAddress');
  static String get addClientProfession => _t('addClientProfession');
  static String get addClientEmergencyContact =>
      _t('addClientEmergencyContact');
  static String get addClientEmergencyContactName =>
      _t('addClientEmergencyContactName');
  static String get addClientEmergencyContactPhone =>
      _t('addClientEmergencyContactPhone');
  static String get addClientPreferredContact =>
      _t('addClientPreferredContact');

  // --- Preferred contact method values (module 1 + module 25) --------------
  static String get contactMethodPhone => _t('contactMethodPhone');
  static String get contactMethodSms => _t('contactMethodSms');
  static String get contactMethodWhatsapp => _t('contactMethodWhatsapp');
  static String get contactMethodEmail => _t('contactMethodEmail');

  // --- Client status (module 1) --------------------------------------------
  static String get clientStatusActive => _t('clientStatusActive');
  static String get clientStatusInactive => _t('clientStatusInactive');
  static String get clientsFilterAllStatuses =>
      _t('clientsFilterAllStatuses');
  static String get clientsTableColStatus => _t('clientsTableColStatus');

  // --- Client header: emergency contact + derived metrics (module 1) ------
  static String get clientHeaderGroupEmergencyContact =>
      _t('clientHeaderGroupEmergencyContact');
  static String get clientMetricFirstVisit => _t('clientMetricFirstVisit');
  static String get clientMetricLastVisit => _t('clientMetricLastVisit');
  static String get clientMetricTotalPurchases =>
      _t('clientMetricTotalPurchases');
  static String get clientMetricLifetimeValue =>
      _t('clientMetricLifetimeValue');

  // --- Client file screen -----------------------------------------------------
  static String get clientFileBackToClients =>
      _t('clientFileBackToClients');
  static String get clientFileNotFoundTitle =>
      _t('clientFileNotFoundTitle');
  static String get clientFileNotFoundSubtitle =>
      _t('clientFileNotFoundSubtitle');
  static String get clientFileTabOverview => _t('clientFileTabOverview');
  static String get clientFileTabAppointments =>
      _t('clientFileTabAppointments');
  static String get clientFileTabExams => _t('clientFileTabExams');
  static String get clientFileTabBilling => _t('clientFileTabBilling');
  static String get clientFileTabDocuments => _t('clientFileTabDocuments');
  static String get clientFileTabTimeline => _t('clientFileTabTimeline');
  static String get clientJourneyStatusLabel =>
      _t('clientJourneyStatusLabel');

  /// "X of Y steps completed" under the client file's journey progress bar
  /// — a plain fraction, not a pluralized count, so no Arabic dual/plural
  /// branching is needed the way [clientsCount] requires.
  static String clientJourneyStepsCompleted(int completed, int total) {
    switch (_languageCode) {
      case 'fr':
        return '$completed sur $total étapes complétées';
      case 'ar':
        return '$completed من $total خطوات مكتملة';
      default:
        return '$completed of $total steps completed';
    }
  }

  // --- Client file: header info groups ------------------------------------------
  static String get clientHeaderGroupIdentity =>
      _t('clientHeaderGroupIdentity');
  static String get clientHeaderGroupPersonal =>
      _t('clientHeaderGroupPersonal');
  static String get clientHeaderGroupContact =>
      _t('clientHeaderGroupContact');

  // --- Client file: section titles --------------------------------------------
  static String get sectionInsurance => _t('sectionInsurance');
  static String get sectionAppointments => _t('sectionAppointments');
  static String get sectionEyeExams => _t('sectionEyeExams');
  static String get sectionInvoices => _t('sectionInvoices');
  static String get sectionPayments => _t('sectionPayments');
  static String get sectionDocuments => _t('sectionDocuments');
  static String get sectionSignatures => _t('sectionSignatures');

  static String get emptyRecordsGeneric => _t('emptyRecordsGeneric');

  // --- Notification bell (global, in AppShell) --------------------------
  static String get notificationsPanelTitle => _t('notificationsPanelTitle');
  static String get notificationsEmpty => _t('notificationsEmpty');
  static String get notificationsSeeAll => _t('notificationsSeeAll');

  // --- Clients table view -------------------------------------------------
  static String get clientsViewCards => _t('clientsViewCards');
  static String get clientsViewTable => _t('clientsViewTable');
  static String get clientsFilterAllGenders => _t('clientsFilterAllGenders');
  static String get clientsFilterAllInsurance =>
      _t('clientsFilterAllInsurance');
  static String get clientsFilterHasInsurance =>
      _t('clientsFilterHasInsurance');
  static String get clientsFilterNoInsurance =>
      _t('clientsFilterNoInsurance');
  static String get clientsResetFilter => _t('clientsResetFilter');
  static String get clientsTableColFileNumber =>
      _t('clientsTableColFileNumber');
  static String get clientsTableColName => _t('clientsTableColName');
  static String get clientsTableColAge => _t('clientsTableColAge');
  static String get clientsTableColPhone => _t('clientsTableColPhone');
  static String get clientsTableColInsurance =>
      _t('clientsTableColInsurance');
  static String get clientsTableNoResults => _t('clientsTableNoResults');

  /// "Showing 1-8 of 23" — plain interpolation (unlike [clientsCount], the
  /// numbers themselves aren't a counted noun needing plural rules, so one
  /// template works across languages).
  static String clientsShowingRange(int start, int end, int total) {
    switch (_languageCode) {
      case 'fr':
        return 'Affichage de $start à $end sur $total';
      case 'ar':
        return 'عرض $start إلى $end من أصل $total';
      default:
        return 'Showing $start-$end of $total';
    }
  }

  // --- Billing screen --------------------------------------------------------
  static String get billingScreenTitle => _t('billingScreenTitle');
  static String get billingChartTitle => _t('billingChartTitle');
  static String get billingKpiPaidTotal => _t('billingKpiPaidTotal');
  static String get billingKpiPendingTotal => _t('billingKpiPendingTotal');
  static String get billingKpiCancelledTotal =>
      _t('billingKpiCancelledTotal');
  static String get billingTabAmount => _t('billingTabAmount');
  static String get billingTabCount => _t('billingTabCount');

  /// Short (3-4 letter) month label for the chart's x-axis — [month] is
  /// 1-12. Not sourced from `kTranslations` like everything else here since
  /// it's 12 short, closely-related values rather than one independent
  /// string; a fixed per-language list reads more clearly than 12 more
  /// `_t()` keys that only this one chart would ever use.
  static String monthAbbreviation(int month) {
    const en = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const fr = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    const ar = [
      'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون',
      'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
    ];
    final index = (month - 1).clamp(0, 11);
    switch (_languageCode) {
      case 'fr':
        return fr[index];
      case 'ar':
        return ar[index];
      default:
        return en[index];
    }
  }

  /// Full month name (1=January ... 12=December) — used by the calendar
  /// screen's headers/date labels. Same fixed-per-language-list approach as
  /// [monthAbbreviation] and for the same reason.
  static String monthFull(int month) {
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const fr = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    const ar = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final index = (month - 1).clamp(0, 11);
    switch (_languageCode) {
      case 'fr':
        return fr[index];
      case 'ar':
        return ar[index];
      default:
        return en[index];
    }
  }

  /// Full weekday name (1=Monday ... 7=Sunday, matching `DateTime.weekday`)
  /// — the calendar's week-view day headers and "Monday, August 18" style
  /// date labels.
  static String weekdayFull(int weekday) {
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const fr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const ar = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final index = (weekday - 1).clamp(0, 6);
    switch (_languageCode) {
      case 'fr':
        return fr[index];
      case 'ar':
        return ar[index];
      default:
        return en[index];
    }
  }

  /// Short weekday label (1=Monday ... 7=Sunday) — the calendar's month-grid
  /// column headers ("Mon Tue Wed ..."). Arabic doesn't have an idiomatic
  /// 3-letter weekday abbreviation the way Latin scripts do, so it falls
  /// back to the full name rather than an invented, unnatural-looking
  /// shortening.
  static String weekdayShort(int weekday) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final index = (weekday - 1).clamp(0, 6);
    switch (_languageCode) {
      case 'fr':
        return fr[index];
      case 'ar':
        return weekdayFull(weekday);
      default:
        return en[index];
    }
  }

  // --- Dashboard header ------------------------------------------------------
  static String get headerGreeting => _t('headerGreeting');
  static String get headerSubtitle => _t('headerSubtitle');
  static String get headerSearchPlaceholder => _t('headerSearchPlaceholder');

  // --- Dashboard: appointments column ----------------------------------------
  static String get dashboardScheduleTodayTitle =>
      _t('dashboardScheduleTodayTitle');
  static String get dashboardScheduleTitle => _t('dashboardScheduleTitle');
  static String get dashboardNoAppointmentsToday =>
      _t('dashboardNoAppointmentsToday');

  // --- Pending tasks panel (dashboard card) -----------------------------------
  static String get pendingTasksSeeAll => _t('pendingTasksSeeAll');
  static String get pendingTasksEmpty => _t('pendingTasksEmpty');

  // --- Pending-task text derived in dashboard_repository.dart -----------------
  static String get taskUnknownClient => _t('taskUnknownClient');
  static String get taskConsentNeedsSignature =>
      _t('taskConsentNeedsSignature');

  // --- Calendar screen ---------------------------------------------------------
  static String get calendarTodayButton => _t('calendarTodayButton');
  static String get calendarNothingScheduled =>
      _t('calendarNothingScheduled');

  // --- Shared "Add X" dialog chrome (add_record_dialog.dart) -------------------
  static String get dialogCancelButton => _t('dialogCancelButton');
  static String get dialogSaveButton => _t('dialogSaveButton');

  // --- Missing-dependency dialog (shown instead of silently doing nothing
  // when an "Add X" button needs an upstream record — a client, order, or
  // supplier — that doesn't exist yet) -------------------------------------
  static String get missingDependencyTitle => _t('missingDependencyTitle');
  static String get missingClientDependencyMessage =>
      _t('missingClientDependencyMessage');
  static String get missingOrderDependencyMessage =>
      _t('missingOrderDependencyMessage');
  static String get missingSupplierDependencyMessage =>
      _t('missingSupplierDependencyMessage');
  static String get missingFrameDependencyMessage =>
      _t('missingFrameDependencyMessage');
  static String get missingLensDependencyMessage =>
      _t('missingLensDependencyMessage');

  // --- "Add X" dialog titles (client_file_screen.dart / add_appointment_dialog.dart) --
  static String get addDialogInsuranceTitle => _t('addDialogInsuranceTitle');
  static String get addDialogEyeExamTitle => _t('addDialogEyeExamTitle');
  static String get addDialogInvoiceTitle => _t('addDialogInvoiceTitle');
  static String get addDialogPaymentTitle => _t('addDialogPaymentTitle');
  static String get addDialogDocumentTitle => _t('addDialogDocumentTitle');
  static String get addDialogSignatureTitle => _t('addDialogSignatureTitle');
  static String get addDialogAppointmentTitle =>
      _t('addDialogAppointmentTitle');

  // --- Settings preview card (settings_screen.dart) ---------------------------
  static String get settingsPreviewSampleCardTitle =>
      _t('settingsPreviewSampleCardTitle');
  static String get settingsPreviewSampleCardBody =>
      _t('settingsPreviewSampleCardBody');
  static String get settingsPreviewIconLabel =>
      _t('settingsPreviewIconLabel');
  static String get settingsPreviewPrimaryButton =>
      _t('settingsPreviewPrimaryButton');
  static String get settingsPreviewOutlineButton =>
      _t('settingsPreviewOutlineButton');

  // --- Client record cards: shared field labels (lib/widgets/*_card.dart) ----
  // Reused across multiple cards wherever the English label is identical —
  // see each card widget for exactly which fields share which key.
  static String get cardFieldDate => _t('cardFieldDate');
  static String get cardFieldType => _t('cardFieldType');
  static String get cardFieldFile => _t('cardFieldFile');
  static String get cardFieldUploaded => _t('cardFieldUploaded');
  static String get cardFieldNotes => _t('cardFieldNotes');
  static String get cardFieldModality => _t('cardFieldModality');
  static String get cardFieldReason => _t('cardFieldReason');
  static String get cardFieldAmount => _t('cardFieldAmount');

  // --- Client record cards: per-card titles/fields ----------------------------
  static String get cardPaymentTitle => _t('cardPaymentTitle');
  static String get cardPaymentMethod => _t('cardPaymentMethod');

  static String get cardClientProfileDob => _t('cardClientProfileDob');
  static String get cardClientProfileGender =>
      _t('cardClientProfileGender');
  static String get cardClientProfileBloodGroup =>
      _t('cardClientProfileBloodGroup');
  static String get cardClientProfileInsurance =>
      _t('cardClientProfileInsurance');
  static String get cardClientProfileNoInsurance =>
      _t('cardClientProfileNoInsurance');

  static String get cardEyeExamTitlePrefix => _t('cardEyeExamTitlePrefix');
  static String get cardEyeExamRefractionPrefix =>
      _t('cardEyeExamRefractionPrefix');
  static String get cardEyeExamVaPrefix => _t('cardEyeExamVaPrefix');
  static String get cardEyeExamIopPrefix => _t('cardEyeExamIopPrefix');

  static String get cardDocumentTitle => _t('cardDocumentTitle');

  static String get cardDigitalSignatureTitle =>
      _t('cardDigitalSignatureTitle');
  static String get cardDigitalSignatureDoctorId =>
      _t('cardDigitalSignatureDoctorId');
  static String get cardDigitalSignatureClientId =>
      _t('cardDigitalSignatureClientId');
  static String get cardDigitalSignatureSignedAt =>
      _t('cardDigitalSignatureSignedAt');

  static String get cardBillingInvoicePrefix =>
      _t('cardBillingInvoicePrefix');

  static String get cardAppointmentWithPrefix =>
      _t('cardAppointmentWithPrefix');

  static String get cardInsuranceTitle => _t('cardInsuranceTitle');
  static String get cardInsuranceProvider => _t('cardInsuranceProvider');
  static String get cardInsurancePolicyNumber =>
      _t('cardInsurancePolicyNumber');
  static String get cardInsuranceValidUntil =>
      _t('cardInsuranceValidUntil');

  // --- Billing screen: appointment-based revenue (replaces the old --------
  // Invoice-based monthly view) --------------------------------------------
  static String get billingKpiTotalThisMonth =>
      _t('billingKpiTotalThisMonth');
  static String get billingKpiVsLastMonth => _t('billingKpiVsLastMonth');
  static String get billingWeeklyChartTitle => _t('billingWeeklyChartTitle');

  // --- Appointment card: type tag + adjustable price / payment status -----
  static String get appointmentTypeNew => _t('appointmentTypeNew');
  static String get appointmentTypeReschedule =>
      _t('appointmentTypeReschedule');
  static String get appointmentPaymentPaid => _t('appointmentPaymentPaid');
  static String get appointmentPaymentUnpaid =>
      _t('appointmentPaymentUnpaid');
  static String get appointmentPaymentNotBillable =>
      _t('appointmentPaymentNotBillable');

  // ===========================================================================
  // Modules 2-6 (optical-retail architecture spec): Prescriptions,
  // Measurements, Frame Inventory, Lens Catalog, Contact Lenses.
  // ===========================================================================

  // --- Shared "Add X" record-field labels, reused across several modules' ---
  // dialogs -------------------------------------------------------------------
  static String get recordFieldClient => _t('recordFieldClient');
  static String get recordFieldBrand => _t('recordFieldBrand');
  static String get recordFieldModel => _t('recordFieldModel');
  static String get recordFieldColor => _t('recordFieldColor');
  static String get recordFieldSize => _t('recordFieldSize');
  static String get recordFieldCost => _t('recordFieldCost');
  static String get recordFieldManufacturer => _t('recordFieldManufacturer');
  static String get recordFieldProductName => _t('recordFieldProductName');

  // --- Client file: new tabs + section titles ------------------------------
  static String get clientFileTabPrescriptions =>
      _t('clientFileTabPrescriptions');
  static String get clientFileTabMeasurements =>
      _t('clientFileTabMeasurements');
  static String get clientFileTabContactLens =>
      _t('clientFileTabContactLens');
  static String get sectionPrescriptions => _t('sectionPrescriptions');
  static String get sectionMeasurements => _t('sectionMeasurements');
  static String get sectionContactLensRx => _t('sectionContactLensRx');

  // --- Optical Consultation (CRM flow diagram) ------------------------------
  static String get addDialogConsultationTitle =>
      _t('addDialogConsultationTitle');
  static String get cardConsultationTitle => _t('cardConsultationTitle');
  static String get consultationAddButton => _t('consultationAddButton');
  static String get consultationKpiTotal => _t('consultationKpiTotal');
  static String get consultationKpiThisMonth =>
      _t('consultationKpiThisMonth');
  static String get consultationKpiHighScreenUsage =>
      _t('consultationKpiHighScreenUsage');
  static String get consultationFieldVisualNeeds =>
      _t('consultationFieldVisualNeeds');
  static String get consultationFieldDailyActivities =>
      _t('consultationFieldDailyActivities');
  static String get consultationFieldScreenUsage =>
      _t('consultationFieldScreenUsage');
  static String get consultationFieldDriving => _t('consultationFieldDriving');
  static String get consultationFieldReading => _t('consultationFieldReading');
  static String get consultationFieldWorkEnvironment =>
      _t('consultationFieldWorkEnvironment');
  static String get consultationFieldPreviousProblems =>
      _t('consultationFieldPreviousProblems');
  static String get consultationScreenUsageLow =>
      _t('consultationScreenUsageLow');
  static String get consultationScreenUsageModerate =>
      _t('consultationScreenUsageModerate');
  static String get consultationScreenUsageHigh =>
      _t('consultationScreenUsageHigh');

  // --- Module 2: Prescriptions -----------------------------------------------
  static String get addDialogPrescriptionTitle =>
      _t('addDialogPrescriptionTitle');
  static String get prescriptionsAddButton => _t('prescriptionsAddButton');
  static String get prescriptionsKpiTotal => _t('prescriptionsKpiTotal');
  static String get prescriptionsKpiThisMonth =>
      _t('prescriptionsKpiThisMonth');
  static String get prescriptionsKpiExpiringSoon =>
      _t('prescriptionsKpiExpiringSoon');
  static String get prescriptionsKpiExpired => _t('prescriptionsKpiExpired');
  static String get prescriptionFieldType => _t('prescriptionFieldType');
  static String get prescriptionTypeDistance =>
      _t('prescriptionTypeDistance');
  static String get prescriptionTypeReading => _t('prescriptionTypeReading');
  static String get prescriptionTypeProgressive =>
      _t('prescriptionTypeProgressive');
  static String get prescriptionTypeOccupational =>
      _t('prescriptionTypeOccupational');
  static String get prescriptionTypeContactLens =>
      _t('prescriptionTypeContactLens');
  static String get cardPrescriptionTitle => _t('cardPrescriptionTitle');
  static String get cardPrescriptionDoctor => _t('cardPrescriptionDoctor');
  static String get cardPrescriptionExpires => _t('cardPrescriptionExpires');
  static String get cardPrescriptionExpired => _t('cardPrescriptionExpired');
  static String get cardPrescriptionPd => _t('cardPrescriptionPd');

  // --- Module 3: Measurements --------------------------------------------------
  static String get addDialogMeasurementTitle =>
      _t('addDialogMeasurementTitle');
  static String get measurementsAddButton => _t('measurementsAddButton');
  static String get measurementsKpiTotal => _t('measurementsKpiTotal');
  static String get measurementsKpiThisMonth =>
      _t('measurementsKpiThisMonth');
  static String get measurementsKpiDigital => _t('measurementsKpiDigital');
  static String get measurementMethodManual => _t('measurementMethodManual');
  static String get measurementMethodPupillometer =>
      _t('measurementMethodPupillometer');
  static String get measurementMethodDigitalCentration =>
      _t('measurementMethodDigitalCentration');
  static String get measurementMethodOpticalScanner =>
      _t('measurementMethodOpticalScanner');
  static String get measurementMethodImported =>
      _t('measurementMethodImported');
  static String get cardMeasurementTitle => _t('cardMeasurementTitle');
  static String get cardMeasurementPd => _t('cardMeasurementPd');
  static String get cardMeasurementFittingHeight =>
      _t('cardMeasurementFittingHeight');
  static String get cardMeasurementFrameGeometry =>
      _t('cardMeasurementFrameGeometry');
  static String get cardMeasurementVertexDistance =>
      _t('cardMeasurementVertexDistance');
  static String get cardMeasurementPantoscopicAngle =>
      _t('cardMeasurementPantoscopicAngle');
  static String get cardMeasurementFaceFormAngle =>
      _t('cardMeasurementFaceFormAngle');
  static String get cardMeasurementMethod => _t('cardMeasurementMethod');
  static String get cardMeasurementOperator => _t('cardMeasurementOperator');

  // --- Module 4: Frame Inventory ----------------------------------------------
  static String get addDialogFrameTitle => _t('addDialogFrameTitle');
  static String get frameInventoryAddButton =>
      _t('frameInventoryAddButton');
  static String get frameInventorySearchPlaceholder =>
      _t('frameInventorySearchPlaceholder');
  static String get frameInventoryKpiTotal => _t('frameInventoryKpiTotal');
  static String get frameInventoryKpiStockValue =>
      _t('frameInventoryKpiStockValue');
  static String get frameInventoryKpiLowStock =>
      _t('frameInventoryKpiLowStock');
  static String get frameInventoryKpiOutOfStock =>
      _t('frameInventoryKpiOutOfStock');
  static String get cardFrameStock => _t('cardFrameStock');
  static String get cardFrameReserved => _t('cardFrameReserved');
  static String get cardFramePrice => _t('cardFramePrice');
  static String get cardFrameSupplier => _t('cardFrameSupplier');
  static String get stockOk => _t('stockOk');
  static String get stockLow => _t('stockLow');
  static String get stockOut => _t('stockOut');

  // --- Module 5: Lens Catalog -------------------------------------------------
  static String get addDialogLensTitle => _t('addDialogLensTitle');
  static String get lensCatalogAddButton => _t('lensCatalogAddButton');
  static String get lensCatalogKpiTotal => _t('lensCatalogKpiTotal');
  static String get lensCatalogKpiAvgPrice => _t('lensCatalogKpiAvgPrice');
  static String get lensCatalogKpiPremium => _t('lensCatalogKpiPremium');
  static String get lensFieldType => _t('lensFieldType');
  static String get lensFilterAllTypes => _t('lensFilterAllTypes');
  static String get lensTypeSingleVision => _t('lensTypeSingleVision');
  static String get lensTypeBifocal => _t('lensTypeBifocal');
  static String get lensTypeProgressive => _t('lensTypeProgressive');
  static String get lensTypeOccupational => _t('lensTypeOccupational');
  static String get lensTypeComputer => _t('lensTypeComputer');
  static String get lensTypeMyopiaControl => _t('lensTypeMyopiaControl');
  static String get lensTypePlano => _t('lensTypePlano');
  static String get lensTypeSunglasses => _t('lensTypeSunglasses');
  static String get lensTypeSpecialty => _t('lensTypeSpecialty');
  static String get cardLensMaterial => _t('cardLensMaterial');
  static String get cardLensIndex => _t('cardLensIndex');
  static String get cardLensCoatings => _t('cardLensCoatings');

  // --- Module 6: Contact Lenses -----------------------------------------------
  static String get addDialogContactLensProductTitle =>
      _t('addDialogContactLensProductTitle');
  static String get addDialogContactLensRxTitle =>
      _t('addDialogContactLensRxTitle');
  static String get contactLensesSectionProducts =>
      _t('contactLensesSectionProducts');
  static String get contactLensesSectionPrescriptions =>
      _t('contactLensesSectionPrescriptions');
  static String get contactLensesAddProductButton =>
      _t('contactLensesAddProductButton');
  static String get contactLensesAddRxButton =>
      _t('contactLensesAddRxButton');
  static String get contactLensesKpiProducts =>
      _t('contactLensesKpiProducts');
  static String get contactLensesKpiClients =>
      _t('contactLensesKpiClients');
  static String get contactLensFieldBoxQuantity =>
      _t('contactLensFieldBoxQuantity');
  static String get cardContactLensRxTitle => _t('cardContactLensRxTitle');

  // --- Modules 7-14 (optical-retail architecture spec) --------------------
  static String get recordFieldSubject => _t('recordFieldSubject');
  static String get recordFieldNotes => _t('recordFieldNotes');
  static String get recordFieldStaffMember => _t('recordFieldStaffMember');
  static String get recordFieldChannel => _t('recordFieldChannel');
  static String get recordFieldDirection => _t('recordFieldDirection');
  static String get recordFieldMethod => _t('recordFieldMethod');
  static String get recordFieldSelectedFrame => _t('recordFieldSelectedFrame');
  static String get recordFieldReason => _t('recordFieldReason');
  static String get recordFieldAccepted => _t('recordFieldAccepted');
  static String get recordFieldCategory => _t('recordFieldCategory');
  static String get recordFieldName => _t('recordFieldName');
  static String get recordFieldDescription => _t('recordFieldDescription');
  static String get recordFieldAmount => _t('recordFieldAmount');
  static String get recordFieldStatus => _t('recordFieldStatus');
  static String get recordFieldValidUntil => _t('recordFieldValidUntil');
  static String get recordFieldOrderId => _t('recordFieldOrderId');
  static String get recordFieldTaskType => _t('recordFieldTaskType');
  static String get recordFieldTechnician => _t('recordFieldTechnician');
  static String get recordFieldDueDate => _t('recordFieldDueDate');
  static String get recordFieldFrame => _t('recordFieldFrame');
  static String get recordFieldLens => _t('recordFieldLens');

  // --- Record fields: cross-module chain links (CRM flow diagram wiring) ---
  static String get recordFieldLinkedConsultation =>
      _t('recordFieldLinkedConsultation');
  static String get recordFieldLinkedPrescription =>
      _t('recordFieldLinkedPrescription');
  static String get recordFieldLinkedMeasurement =>
      _t('recordFieldLinkedMeasurement');
  static String get recordFieldLinkedFrameSelection =>
      _t('recordFieldLinkedFrameSelection');
  static String get recordFieldLinkedLensRecommendation =>
      _t('recordFieldLinkedLensRecommendation');
  static String get recordFieldLinkedAccessory =>
      _t('recordFieldLinkedAccessory');
  static String get recordFieldLinkedAfterSalesTicket =>
      _t('recordFieldLinkedAfterSalesTicket');
  static String get recordFieldTriggeringOrder =>
      _t('recordFieldTriggeringOrder');

  // --- Generic yes/no, used by boolean detail-dialog rows -----------------
  static String get dialogYes => _t('dialogYes');
  static String get dialogNo => _t('dialogNo');
  static String get cardCommunicationStaff => _t('cardCommunicationStaff');
  static String get addDialogCommunicationTitle => _t('addDialogCommunicationTitle');
  static String get communicationAddButton => _t('communicationAddButton');
  static String get communicationKpiTotal => _t('communicationKpiTotal');
  static String get communicationKpiThisMonth => _t('communicationKpiThisMonth');
  static String get communicationKpiFollowUps => _t('communicationKpiFollowUps');
  static String get commChannelPhone => _t('commChannelPhone');
  static String get commChannelSms => _t('commChannelSms');
  static String get commChannelWhatsapp => _t('commChannelWhatsapp');
  static String get commChannelEmail => _t('commChannelEmail');
  static String get commChannelInPerson => _t('commChannelInPerson');
  static String get commDirectionInbound => _t('commDirectionInbound');
  static String get commDirectionOutbound => _t('commDirectionOutbound');
  static String get commFollowUpRequired => _t('commFollowUpRequired');
  static String get addDialogFrameSelectionTitle => _t('addDialogFrameSelectionTitle');
  static String get frameSelectionAddButton => _t('frameSelectionAddButton');
  static String get frameSelectionKpiTotal => _t('frameSelectionKpiTotal');
  static String get frameSelectionKpiThisMonth => _t('frameSelectionKpiThisMonth');
  static String get frameSelectionKpiVirtual => _t('frameSelectionKpiVirtual');
  static String get frameSelectionKpiConversion => _t('frameSelectionKpiConversion');
  static String get frameSelectionMethodInStore => _t('frameSelectionMethodInStore');
  static String get frameSelectionMethodVirtual => _t('frameSelectionMethodVirtual');
  static String get cardFrameSelectionTried => _t('cardFrameSelectionTried');
  static String get cardFrameSelectionUndecided => _t('cardFrameSelectionUndecided');
  static String get addDialogLensRecommendationTitle => _t('addDialogLensRecommendationTitle');
  static String get lensRecommendationAddButton => _t('lensRecommendationAddButton');
  static String get lensRecommendationKpiTotal => _t('lensRecommendationKpiTotal');
  static String get lensRecommendationKpiThisMonth => _t('lensRecommendationKpiThisMonth');
  static String get lensRecommendationKpiAcceptanceRate => _t('lensRecommendationKpiAcceptanceRate');
  static String get cardLensRecAccepted => _t('cardLensRecAccepted');
  static String get cardLensRecPending => _t('cardLensRecPending');
  static String get addDialogAccessoryTitle => _t('addDialogAccessoryTitle');
  static String get accessoriesAddButton => _t('accessoriesAddButton');
  static String get accessoriesKpiTotal => _t('accessoriesKpiTotal');
  static String get accessoriesKpiStockValue => _t('accessoriesKpiStockValue');
  static String get accessoriesKpiLowStock => _t('accessoriesKpiLowStock');
  static String get accessoryCategoryCase => _t('accessoryCategoryCase');
  static String get accessoryCategoryCleaningSolution => _t('accessoryCategoryCleaningSolution');
  static String get accessoryCategoryCloth => _t('accessoryCategoryCloth');
  static String get accessoryCategoryChain => _t('accessoryCategoryChain');
  static String get accessoryCategoryRepairKit => _t('accessoryCategoryRepairKit');
  static String get accessoryCategoryOther => _t('accessoryCategoryOther');
  static String get addDialogQuoteTitle => _t('addDialogQuoteTitle');
  static String get quotesAddButton => _t('quotesAddButton');
  static String get quotesKpiTotal => _t('quotesKpiTotal');
  static String get quotesKpiThisMonth => _t('quotesKpiThisMonth');
  static String get quotesKpiAccepted => _t('quotesKpiAccepted');
  static String get quotesKpiPendingValue => _t('quotesKpiPendingValue');
  static String get quoteStatusDraft => _t('quoteStatusDraft');
  static String get quoteStatusSent => _t('quoteStatusSent');
  static String get quoteStatusAccepted => _t('quoteStatusAccepted');
  static String get quoteStatusDeclined => _t('quoteStatusDeclined');
  static String get quoteStatusExpired => _t('quoteStatusExpired');
  static String get cardQuoteValidUntil => _t('cardQuoteValidUntil');
  static String get addDialogOrderTitle => _t('addDialogOrderTitle');
  static String get ordersAddButton => _t('ordersAddButton');
  static String get ordersKpiTotal => _t('ordersKpiTotal');
  static String get ordersKpiThisMonth => _t('ordersKpiThisMonth');
  static String get ordersKpiInProduction => _t('ordersKpiInProduction');
  static String get ordersKpiRevenue => _t('ordersKpiRevenue');
  static String get orderStatusPending => _t('orderStatusPending');
  static String get orderStatusInProduction => _t('orderStatusInProduction');
  static String get orderStatusReady => _t('orderStatusReady');
  static String get orderStatusDelivered => _t('orderStatusDelivered');
  static String get orderStatusCancelled => _t('orderStatusCancelled');
  static String get addDialogLabWorkOrderTitle => _t('addDialogLabWorkOrderTitle');
  static String get laboratoryAddButton => _t('laboratoryAddButton');
  static String get laboratoryKpiTotal => _t('laboratoryKpiTotal');
  static String get laboratoryKpiInProgress => _t('laboratoryKpiInProgress');
  static String get laboratoryKpiOverdue => _t('laboratoryKpiOverdue');
  static String get laboratoryKpiCompletedThisMonth => _t('laboratoryKpiCompletedThisMonth');
  static String get labTaskLensCutting => _t('labTaskLensCutting');
  static String get labTaskEdging => _t('labTaskEdging');
  static String get labTaskCoating => _t('labTaskCoating');
  static String get labTaskTinting => _t('labTaskTinting');
  static String get labTaskEngraving => _t('labTaskEngraving');
  static String get labTaskOther => _t('labTaskOther');
  static String get labStatusQueued => _t('labStatusQueued');
  static String get labStatusInProgress => _t('labStatusInProgress');
  static String get labStatusQualityHold => _t('labStatusQualityHold');
  static String get labStatusCompleted => _t('labStatusCompleted');
  static String get labOverdue => _t('labOverdue');
  static String get cardLabTechnician => _t('cardLabTechnician');
  static String get cardLabDueDate => _t('cardLabDueDate');
  static String get addDialogMountingTitle => _t('addDialogMountingTitle');
  static String get mountingAddButton => _t('mountingAddButton');
  static String get mountingKpiTotal => _t('mountingKpiTotal');
  static String get mountingKpiInProgress => _t('mountingKpiInProgress');
  static String get mountingKpiCompletedThisMonth => _t('mountingKpiCompletedThisMonth');
  static String get mountingKpiRework => _t('mountingKpiRework');
  static String get mountingStatusPending => _t('mountingStatusPending');
  static String get mountingStatusInProgress => _t('mountingStatusInProgress');
  static String get mountingStatusCompleted => _t('mountingStatusCompleted');
  static String get mountingStatusRework => _t('mountingStatusRework');
  static String get cardMountingLens => _t('cardMountingLens');
  static String get cardMountingTechnician => _t('cardMountingTechnician');
  static String get cardMountingCompleted => _t('cardMountingCompleted');

  // --- Modules 15-22 (optical-retail architecture spec) -------------------
  static String get recordFieldCheckType => _t('recordFieldCheckType');
  static String get recordFieldResult => _t('recordFieldResult');
  static String get recordFieldInspector => _t('recordFieldInspector');
  static String get recordFieldAdjustmentType => _t('recordFieldAdjustmentType');
  static String get recordFieldComfortRating => _t('recordFieldComfortRating');
  static String get recordFieldIssueType => _t('recordFieldIssueType');
  static String get recordFieldResolution => _t('recordFieldResolution');
  static String get recordFieldItemType => _t('recordFieldItemType');
  static String get recordFieldIssueDescription => _t('recordFieldIssueDescription');
  static String get recordFieldContactPerson => _t('recordFieldContactPerson');
  static String get recordFieldPaymentTerms => _t('recordFieldPaymentTerms');
  static String get recordFieldSupplier => _t('recordFieldSupplier');
  static String get recordFieldExpectedDate => _t('recordFieldExpectedDate');
  static String get addDialogQualityCheckTitle => _t('addDialogQualityCheckTitle');
  static String get qualityControlAddButton => _t('qualityControlAddButton');
  static String get qualityControlKpiTotal => _t('qualityControlKpiTotal');
  static String get qualityControlKpiPassRate => _t('qualityControlKpiPassRate');
  static String get qualityControlKpiFailed => _t('qualityControlKpiFailed');
  static String get qcTypeFrameFit => _t('qcTypeFrameFit');
  static String get qcTypeLensQuality => _t('qcTypeLensQuality');
  static String get qcTypePrescriptionAccuracy => _t('qcTypePrescriptionAccuracy');
  static String get qcTypeCosmetic => _t('qcTypeCosmetic');
  static String get qcTypeOther => _t('qcTypeOther');
  static String get qcResultPass => _t('qcResultPass');
  static String get qcResultConditionalPass => _t('qcResultConditionalPass');
  static String get qcResultFail => _t('qcResultFail');
  static String get cardQcInspector => _t('cardQcInspector');
  static String get qcCreateFinalFittingAction =>
      _t('qcCreateFinalFittingAction');
  static String get qcCreateReworkAction => _t('qcCreateReworkAction');
  static String get qcFinalFittingCreatedSnackbar =>
      _t('qcFinalFittingCreatedSnackbar');
  static String get qcReworkCreatedSnackbar => _t('qcReworkCreatedSnackbar');
  static String get addDialogFinalFittingTitle => _t('addDialogFinalFittingTitle');
  static String get finalFittingAddButton => _t('finalFittingAddButton');
  static String get finalFittingKpiTotal => _t('finalFittingKpiTotal');
  static String get finalFittingKpiThisMonth => _t('finalFittingKpiThisMonth');
  static String get finalFittingKpiAvgComfort => _t('finalFittingKpiAvgComfort');
  static String get fittingTypeNosePads => _t('fittingTypeNosePads');
  static String get fittingTypeTempleLength => _t('fittingTypeTempleLength');
  static String get fittingTypeFrameAlignment => _t('fittingTypeFrameAlignment');
  static String get fittingTypeLensPosition => _t('fittingTypeLensPosition');
  static String get fittingTypeOther => _t('fittingTypeOther');
  static String get addDialogDeliveryTitle => _t('addDialogDeliveryTitle');
  static String get deliveryAddButton => _t('deliveryAddButton');
  static String get deliveryKpiThisMonth => _t('deliveryKpiThisMonth');
  static String get deliveryKpiScheduled => _t('deliveryKpiScheduled');
  static String get deliveryKpiDelivered => _t('deliveryKpiDelivered');
  static String get deliveryMethodInStore => _t('deliveryMethodInStore');
  static String get deliveryMethodHome => _t('deliveryMethodHome');
  static String get deliveryMethodCourier => _t('deliveryMethodCourier');
  static String get deliveryStatusScheduled => _t('deliveryStatusScheduled');
  static String get deliveryStatusDelivered => _t('deliveryStatusDelivered');
  static String get deliveryStatusFailed => _t('deliveryStatusFailed');
  static String get deliverySigned => _t('deliverySigned');
  static String get deliveryNotSigned => _t('deliveryNotSigned');
  static String get addDialogAfterSalesTitle => _t('addDialogAfterSalesTitle');
  static String get afterSalesAddButton => _t('afterSalesAddButton');
  static String get afterSalesKpiTotal => _t('afterSalesKpiTotal');
  static String get afterSalesKpiOpen => _t('afterSalesKpiOpen');
  static String get afterSalesKpiResolved => _t('afterSalesKpiResolved');
  static String get afterSalesIssueComfort => _t('afterSalesIssueComfort');
  static String get afterSalesIssueBreakage => _t('afterSalesIssueBreakage');
  static String get afterSalesIssueVision => _t('afterSalesIssueVision');
  static String get afterSalesIssueOther => _t('afterSalesIssueOther');
  static String get afterSalesStatusOpen => _t('afterSalesStatusOpen');
  static String get afterSalesStatusInProgress => _t('afterSalesStatusInProgress');
  static String get afterSalesStatusResolved => _t('afterSalesStatusResolved');
  static String get afterSalesStatusClosed => _t('afterSalesStatusClosed');
  static String get afterSalesFieldOutcome => _t('afterSalesFieldOutcome');
  static String get afterSalesOutcomePending => _t('afterSalesOutcomePending');
  static String get afterSalesOutcomeSatisfied =>
      _t('afterSalesOutcomeSatisfied');
  static String get afterSalesOutcomeComplaint =>
      _t('afterSalesOutcomeComplaint');
  static String get afterSalesOutcomeRepair => _t('afterSalesOutcomeRepair');
  static String get addDialogRepairTitle => _t('addDialogRepairTitle');
  static String get repairsAddButton => _t('repairsAddButton');
  static String get repairsKpiTotal => _t('repairsKpiTotal');
  static String get repairsKpiInProgress => _t('repairsKpiInProgress');
  static String get repairsKpiRevenue => _t('repairsKpiRevenue');
  static String get repairItemFrame => _t('repairItemFrame');
  static String get repairItemLens => _t('repairItemLens');
  static String get repairItemContactLens => _t('repairItemContactLens');
  static String get repairItemOther => _t('repairItemOther');
  static String get repairStatusReceived => _t('repairStatusReceived');
  static String get repairStatusInProgress => _t('repairStatusInProgress');
  static String get repairStatusCompleted => _t('repairStatusCompleted');
  static String get repairStatusCannotRepair => _t('repairStatusCannotRepair');
  static String get addDialogWarrantyTitle => _t('addDialogWarrantyTitle');
  static String get warrantyAddButton => _t('warrantyAddButton');
  static String get warrantyKpiTotal => _t('warrantyKpiTotal');
  static String get warrantyKpiPending => _t('warrantyKpiPending');
  static String get warrantyKpiApproved => _t('warrantyKpiApproved');
  static String get warrantyStatusSubmitted => _t('warrantyStatusSubmitted');
  static String get warrantyStatusApproved => _t('warrantyStatusApproved');
  static String get warrantyStatusRejected => _t('warrantyStatusRejected');
  static String get warrantyStatusReplaced => _t('warrantyStatusReplaced');
  static String get addDialogSupplierTitle => _t('addDialogSupplierTitle');
  static String get suppliersAddButton => _t('suppliersAddButton');
  static String get suppliersKpiTotal => _t('suppliersKpiTotal');
  static String get suppliersKpiAvgRating => _t('suppliersKpiAvgRating');
  static String get supplierCategoryFrames => _t('supplierCategoryFrames');
  static String get supplierCategoryLenses => _t('supplierCategoryLenses');
  static String get supplierCategoryContactLenses => _t('supplierCategoryContactLenses');
  static String get supplierCategoryAccessories => _t('supplierCategoryAccessories');
  static String get supplierCategoryGeneral => _t('supplierCategoryGeneral');
  static String get cardSupplierContact => _t('cardSupplierContact');
  static String get cardSupplierTerms => _t('cardSupplierTerms');
  static String get addDialogPurchaseOrderTitle => _t('addDialogPurchaseOrderTitle');
  static String get purchasingAddButton => _t('purchasingAddButton');
  static String get purchasingKpiTotal => _t('purchasingKpiTotal');
  static String get purchasingKpiPendingValue => _t('purchasingKpiPendingValue');
  static String get purchasingKpiReceived => _t('purchasingKpiReceived');
  static String get poStatusDraft => _t('poStatusDraft');
  static String get poStatusSent => _t('poStatusSent');
  static String get poStatusConfirmed => _t('poStatusConfirmed');
  static String get poStatusReceived => _t('poStatusReceived');
  static String get poStatusCancelled => _t('poStatusCancelled');
  static String get cardPoExpected => _t('cardPoExpected');

  // --- Dashboard customization (Settings > Dashboard tab) -----------------
  static String get settingsDashboardTab => _t('settingsDashboardTab');
  static String get settingsDashboardIntro => _t('settingsDashboardIntro');
  static String get dashWidgetMonthlyRevenue => _t('dashWidgetMonthlyRevenue');
  static String get dashWidgetMonthlyRevenueDesc => _t('dashWidgetMonthlyRevenueDesc');
  static String get dashWidgetQuickActions => _t('dashWidgetQuickActions');
  static String get dashWidgetQuickActionsDesc => _t('dashWidgetQuickActionsDesc');
  static String get dashWidgetTodaysSnapshot => _t('dashWidgetTodaysSnapshot');
  static String get dashWidgetTodaysSnapshotDesc => _t('dashWidgetTodaysSnapshotDesc');
  static String get dashWidgetCalendarAppointments => _t('dashWidgetCalendarAppointments');
  static String get dashWidgetCalendarAppointmentsDesc => _t('dashWidgetCalendarAppointmentsDesc');
  static String get dashWidgetPendingTasks => _t('dashWidgetPendingTasks');
  static String get dashWidgetPendingTasksDesc => _t('dashWidgetPendingTasksDesc');
  static String get dashWidgetClientsOverview => _t('dashWidgetClientsOverview');
  static String get dashWidgetClientsOverviewDesc => _t('dashWidgetClientsOverviewDesc');
  static String get dashWidgetInventoryAlerts => _t('dashWidgetInventoryAlerts');
  static String get dashWidgetInventoryAlertsDesc => _t('dashWidgetInventoryAlertsDesc');
  static String get dashWidgetPrescriptionAlerts => _t('dashWidgetPrescriptionAlerts');
  static String get dashWidgetPrescriptionAlertsDesc => _t('dashWidgetPrescriptionAlertsDesc');
  static String get dashWidgetOrdersPipeline => _t('dashWidgetOrdersPipeline');
  static String get dashWidgetOrdersPipelineDesc => _t('dashWidgetOrdersPipelineDesc');
  static String get dashWidgetQuotesPipeline => _t('dashWidgetQuotesPipeline');
  static String get dashWidgetQuotesPipelineDesc => _t('dashWidgetQuotesPipelineDesc');
  static String get dashWidgetAfterSalesOverview => _t('dashWidgetAfterSalesOverview');
  static String get dashWidgetAfterSalesOverviewDesc => _t('dashWidgetAfterSalesOverviewDesc');
  static String get dashWidgetQualityOverview => _t('dashWidgetQualityOverview');
  static String get dashWidgetQualityOverviewDesc => _t('dashWidgetQualityOverviewDesc');
  static String get dashRevenueTitle => _t('dashRevenueTitle');
  static String get dashRevenueVsLastMonth => _t('dashRevenueVsLastMonth');
  static String get dashRevenueNoComparison => _t('dashRevenueNoComparison');
  static String get dashClientsTotal => _t('dashClientsTotal');
  static String get dashClientsActive => _t('dashClientsActive');
  static String get dashClientsNewThisMonth => _t('dashClientsNewThisMonth');
  static String get dashInventoryLowStock => _t('dashInventoryLowStock');
  static String get dashInventoryOutOfStock => _t('dashInventoryOutOfStock');
  static String get dashPrescriptionsExpiringSoon => _t('dashPrescriptionsExpiringSoon');
  static String get dashPrescriptionsExpired => _t('dashPrescriptionsExpired');
  static String get dashOrdersPending => _t('dashOrdersPending');
  static String get dashOrdersInProduction => _t('dashOrdersInProduction');
  static String get dashOrdersReady => _t('dashOrdersReady');
  static String get dashQuotesPendingValue => _t('dashQuotesPendingValue');
  static String get dashQuotesAccepted => _t('dashQuotesAccepted');
  static String get dashAfterSalesOpen => _t('dashAfterSalesOpen');
  static String get dashRepairsInProgress => _t('dashRepairsInProgress');
  static String get dashQualityPassRate => _t('dashQualityPassRate');
  static String get dashLabOverdue => _t('dashLabOverdue');
  // --- Redesign (Aug 2026): operational-center hero row + recent clients ---
  static String get dashHeroClients => _t('dashHeroClients');
  static String get dashHeroOrders => _t('dashHeroOrders');
  static String get dashHeroRevenue => _t('dashHeroRevenue');
  static String get dashHeroPending => _t('dashHeroPending');
  static String get dashWidgetRecentClients => _t('dashWidgetRecentClients');
  static String get dashWidgetRecentClientsDesc => _t('dashWidgetRecentClientsDesc');
  static String get dashRecentClientsEmpty => _t('dashRecentClientsEmpty');
  static String get dashRecentClientsNoVisit => _t('dashRecentClientsNoVisit');
  // --- Navigation-fix pass (Sign out / Tasks / order pipeline / quote-to-order / linked-order picker) ---
  static String get confirmSignOutTitle => _t('confirmSignOutTitle');
  static String get confirmSignOutMessage => _t('confirmSignOutMessage');
  static String get confirmSignOutButton => _t('confirmSignOutButton');
  static String get dialogCloseButton => _t('dialogCloseButton');
  static String get deleteButtonLabel => _t('deleteButtonLabel');
  static String get deleteConfirmTitle => _t('deleteConfirmTitle');
  static String get deleteConfirmMessage => _t('deleteConfirmMessage');
  static String get deleteConfirmButton => _t('deleteConfirmButton');
  static String get clientFileDeleteButton => _t('clientFileDeleteButton');
  static String get clientFileDeleteConfirmTitle =>
      _t('clientFileDeleteConfirmTitle');
  static String get clientFileDeleteConfirmMessage =>
      _t('clientFileDeleteConfirmMessage');
  static String get recordActionViewDetails => _t('recordActionViewDetails');
  static String get recordActionGoToClient => _t('recordActionGoToClient');
  static String get recordActionEdit => _t('recordActionEdit');
  static String get editDialogPrescriptionTitle =>
      _t('editDialogPrescriptionTitle');
  static String get orderPipelineLab => _t('orderPipelineLab');
  static String get orderPipelineMounting => _t('orderPipelineMounting');
  static String get orderPipelineQuality => _t('orderPipelineQuality');
  static String get orderPipelineFitting => _t('orderPipelineFitting');
  static String get orderPipelineDelivery => _t('orderPipelineDelivery');
  static String get orderPipelineNotStarted => _t('orderPipelineNotStarted');
  static String get clientFileNewQuote => _t('clientFileNewQuote');
  static String get clientFileNewOrder => _t('clientFileNewOrder');
  static String get quoteConvertToOrder => _t('quoteConvertToOrder');
  static String get quoteAlreadyConverted => _t('quoteAlreadyConverted');
  static String get quoteConvertedSnackbar => _t('quoteConvertedSnackbar');
  static String get recordFieldLinkedOrder => _t('recordFieldLinkedOrder');
  static String get recordFieldNoneOption => _t('recordFieldNoneOption');
  static String get signedOutMessage => _t('signedOutMessage');
  static String get tasksScreenSubtitle => _t('tasksScreenSubtitle');
  static String get tasksKpiTotal => _t('tasksKpiTotal');
  static String get tasksKpiLinkedToClient => _t('tasksKpiLinkedToClient');
  static String get monthFilterThisMonth => _t('monthFilterThisMonth');
  static String get topBarSearchPlaceholder => _t('topBarSearchPlaceholder');
  static String get topBarNewButton => _t('topBarNewButton');
  static String get topBarNewQuote => _t('topBarNewQuote');
  static String get topBarNewOrder => _t('topBarNewOrder');
  static String get topBarNoResults => _t('topBarNoResults');
  static String get topBarGreetingMorning => _t('topBarGreetingMorning');
  static String get topBarGreetingAfternoon => _t('topBarGreetingAfternoon');
  static String get topBarGreetingEvening => _t('topBarGreetingEvening');
  static String get recordFieldTime => _t('recordFieldTime');
  static String get recordFieldDoctor => _t('recordFieldDoctor');
  static String get recordFieldSku => _t('recordFieldSku');
  static String get recordFieldPowerOD => _t('recordFieldPowerOD');
  static String get recordFieldBcOD => _t('recordFieldBcOD');
  static String get recordFieldDiaOD => _t('recordFieldDiaOD');
  static String get recordFieldPowerOS => _t('recordFieldPowerOS');
  static String get recordFieldBcOS => _t('recordFieldBcOS');
  static String get recordFieldDiaOS => _t('recordFieldDiaOS');
  static String get recordFieldPdMm => _t('recordFieldPdMm');
  static String get recordFieldBridgeMm => _t('recordFieldBridgeMm');
  static String get recordFieldTempleLengthMm => _t('recordFieldTempleLengthMm');
  static String get recordFieldExamDate => _t('recordFieldExamDate');
  static String get recordFieldVisualAcuityOD => _t('recordFieldVisualAcuityOD');
  static String get recordFieldVisualAcuityOS => _t('recordFieldVisualAcuityOS');
  static String get recordFieldIopOD => _t('recordFieldIopOD');
  static String get recordFieldIopOS => _t('recordFieldIopOS');
  static String get recordFieldSph => _t('recordFieldSph');
  static String get recordFieldCyl => _t('recordFieldCyl');
  static String get recordFieldAxis => _t('recordFieldAxis');
  static String get recordFieldSphOD => _t('recordFieldSphOD');
  static String get recordFieldSphOS => _t('recordFieldSphOS');
  static String get recordFieldCylOD => _t('recordFieldCylOD');
  static String get recordFieldAxisOD => _t('recordFieldAxisOD');
  static String get recordFieldCylOS => _t('recordFieldCylOS');
  static String get recordFieldAxisOS => _t('recordFieldAxisOS');
  static String get recordFieldProvider => _t('recordFieldProvider');
  static String get recordFieldPolicyNumber => _t('recordFieldPolicyNumber');
  static String get recordFieldType => _t('recordFieldType');
  static String get recordFieldFilePath => _t('recordFieldFilePath');
  static String get recordFieldDoctorId => _t('recordFieldDoctorId');
  static String get recordFieldSignatureData => _t('recordFieldSignatureData');
  static String get recordFieldInvoice => _t('recordFieldInvoice');
  static String get recordFieldPhone => _t('recordFieldPhone');
  static String get recordFieldEmail => _t('recordFieldEmail');
  static String get clientFileAddInvoice => _t('clientFileAddInvoice');
  static String get clientFileAddPayment => _t('clientFileAddPayment');
  static String get clientFileAddDocument => _t('clientFileAddDocument');
  static String get clientFileAddSignature => _t('clientFileAddSignature');
  static String get hintAppointmentReason => _t('hintAppointmentReason');
  static String get hintVisualAcuity => _t('hintVisualAcuity');
  static String get hintPaymentMethod => _t('hintPaymentMethod');
  static String get hintDocumentType => _t('hintDocumentType');
  static String get hintSignatureData => _t('hintSignatureData');

  // --- Redesign (Aug 2026): minimalist operational-center dashboard rebuild ---
  static String get dashRangeToday => _t('dashRangeToday');
  static String get dashRangeThisWeek => _t('dashRangeThisWeek');
  static String get dashRangeThisMonth => _t('dashRangeThisMonth');
  static String get dashRangeCustom => _t('dashRangeCustom');
  static String get dashWidgetAttention => _t('dashWidgetAttention');
  static String get dashWidgetAttentionDesc => _t('dashWidgetAttentionDesc');
  static String get dashWidgetTasksAndAppointments =>
      _t('dashWidgetTasksAndAppointments');
  static String get dashWidgetTasksAndAppointmentsDesc =>
      _t('dashWidgetTasksAndAppointmentsDesc');
  static String get dashWidgetSalesAndActivity =>
      _t('dashWidgetSalesAndActivity');
  static String get dashWidgetSalesAndActivityDesc =>
      _t('dashWidgetSalesAndActivityDesc');
  static String get dashWidgetInventoryAndActions =>
      _t('dashWidgetInventoryAndActions');
  static String get dashWidgetInventoryAndActionsDesc =>
      _t('dashWidgetInventoryAndActionsDesc');
  static String get dashKpiClients => _t('dashKpiClients');
  static String get dashKpiClientsSub => _t('dashKpiClientsSub');
  static String get dashKpiAppointments => _t('dashKpiAppointments');
  static String get dashKpiAppointmentsSub => _t('dashKpiAppointmentsSub');
  static String get dashKpiSales => _t('dashKpiSales');
  static String get dashKpiOrders => _t('dashKpiOrders');
  static String get dashKpiOrdersSub => _t('dashKpiOrdersSub');
  static String get dashAttentionTitle => _t('dashAttentionTitle');
  static String get dashAttentionEmpty => _t('dashAttentionEmpty');
  static String get dashAttentionOrdersReady => _t('dashAttentionOrdersReady');
  static String get dashAttentionLowStock => _t('dashAttentionLowStock');
  static String get dashAttentionOverduePayments =>
      _t('dashAttentionOverduePayments');
  static String get dashAttentionUnconfirmedAppointments =>
      _t('dashAttentionUnconfirmedAppointments');
  static String get dashPanelTasksTitle => _t('dashPanelTasksTitle');
  static String get dashPanelAppointmentsTitle =>
      _t('dashPanelAppointmentsTitle');
  static String get dashPanelSalesTitle => _t('dashPanelSalesTitle');
  static String get dashPanelActivityTitle => _t('dashPanelActivityTitle');
  static String get dashPanelInventoryTitle => _t('dashPanelInventoryTitle');
  static String get dashPanelQuickActionsTitle =>
      _t('dashPanelQuickActionsTitle');
  static String get dashViewAll => _t('dashViewAll');
  static String get dashSalesVsPrevious => _t('dashSalesVsPrevious');
  static String get dashActivityEmpty => _t('dashActivityEmpty');
  static String get dashAppointmentsEmptyUpcoming =>
      _t('dashAppointmentsEmptyUpcoming');
  static String get dashQuickActionSale => _t('dashQuickActionSale');
  static String get dashQuickActionExam => _t('dashQuickActionExam');
  static String get dashActivityOrderPlaced => _t('dashActivityOrderPlaced');
  static String get dashActivityPaymentReceived =>
      _t('dashActivityPaymentReceived');
  static String get dashActivityPrescriptionUpdated =>
      _t('dashActivityPrescriptionUpdated');
  static String get dashActivityNewClient => _t('dashActivityNewClient');

  // --- Auth / sign in -----------------------------------------------------
  static String get authSignInTitle => _t('authSignInTitle');
  static String get authEmailLabel => _t('authEmailLabel');
  static String get authPasswordLabel => _t('authPasswordLabel');
  static String get authSignInButton => _t('authSignInButton');
  static String get authForgotPasswordLink => _t('authForgotPasswordLink');
  static String get authResetPasswordSentMessage =>
      _t('authResetPasswordSentMessage');
  static String get authResolvingWorkspace => _t('authResolvingWorkspace');
  static String get authErrorGeneric => _t('authErrorGeneric');
  static String get authErrorInvalidCredentials =>
      _t('authErrorInvalidCredentials');
  static String get authErrorInvalidEmail => _t('authErrorInvalidEmail');
}
