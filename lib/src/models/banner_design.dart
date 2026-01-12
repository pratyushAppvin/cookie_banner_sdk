/// Banner design configuration mirroring TypeScript `BannerDesign` interface.
class BannerDesign {
  final String consentTabHeading;
  final String detailsTabHeading;
  final String aboutTabHeading;
  final String bannerHeading;
  final String bannerDescription;
  final String? detailsTabDescription;
  final BannerButtons? buttons;
  final BannerButtonsStyles? buttonStyles;
  final List<String>? buttonOrder;
  final String denyButtonLabel;
  final String allowSelectionButtonLabel;
  final String allowAllButtonLabel;
  final String saveChoicesButtonLabel;
  
  // Preference Modal Button Configuration (for footer layout dialog)
  final BannerButtons? preferenceModalButtons;
  final BannerButtonsStyles? preferenceModalButtonStyles;
  final List<String>? preferenceModalButtonOrder;
  final String? preferenceModalDenyButtonLabel;
  final String? preferenceModalSaveChoicesButtonLabel;
  final String? preferenceModalAllowAllButtonLabel;
  
  final String aboutSectionContent;
  final String backgroundColor;
  final String fontColor;
  final String textSize;
  final String fontFamily;
  final String cookiePolicyUrl;
  final String logoUrl;
  final LogoSize logoSize;
  final String colorScheme;
  final String buttonColor;
  final String showLogo;
  final String layoutType; // 'wall' or 'footer'
  final String? privacyPolicyUrl;
  final bool showLanguageDropdown;
  final bool automaticLanguageDetection;
  final bool defaultOptIn;
  final bool allowBannerClose;

  const BannerDesign({
    required this.consentTabHeading,
    required this.detailsTabHeading,
    required this.aboutTabHeading,
    required this.bannerHeading,
    required this.bannerDescription,
    this.detailsTabDescription,
    this.buttons,
    this.buttonStyles,
    this.buttonOrder,
    required this.denyButtonLabel,
    required this.allowSelectionButtonLabel,
    required this.allowAllButtonLabel,
    required this.saveChoicesButtonLabel,
    this.preferenceModalButtons,
    this.preferenceModalButtonStyles,
    this.preferenceModalButtonOrder,
    this.preferenceModalDenyButtonLabel,
    this.preferenceModalSaveChoicesButtonLabel,
    this.preferenceModalAllowAllButtonLabel,
    required this.aboutSectionContent,
    required this.backgroundColor,
    required this.fontColor,
    required this.textSize,
    required this.fontFamily,
    required this.cookiePolicyUrl,
    required this.logoUrl,
    required this.logoSize,
    required this.colorScheme,
    required this.buttonColor,
    required this.showLogo,
    required this.layoutType,
    this.privacyPolicyUrl,
    required this.showLanguageDropdown,
    required this.automaticLanguageDetection,
    required this.defaultOptIn,
    required this.allowBannerClose,
  });

  factory BannerDesign.fromJson(Map<String, dynamic> json) {
    return BannerDesign(
      consentTabHeading: json['consentTabHeading'] as String? ?? '',
      detailsTabHeading: json['detailsTabHeading'] as String? ?? '',
      aboutTabHeading: json['aboutTabHeading'] as String? ?? '',
      bannerHeading: json['bannerHeading'] as String? ?? '',
      bannerDescription: json['bannerDescription'] as String? ?? '',
      detailsTabDescription: json['detailsTabDescription'] as String?,
      buttons: json['buttons'] != null
          ? BannerButtons.fromJson(json['buttons'] as Map<String, dynamic>)
          : null,
      buttonStyles: json['buttonStyles'] != null
          ? BannerButtonsStyles.fromJson(
              json['buttonStyles'] as Map<String, dynamic>)
          : null,
      buttonOrder: (json['buttonOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      denyButtonLabel: json['denyButtonLabel'] as String? ?? 'Deny',
      allowSelectionButtonLabel:
          json['allowSelectionButtonLabel'] as String? ?? 'Allow Selection',
      allowAllButtonLabel:
          json['allowAllButtonLabel'] as String? ?? 'Allow All',
      saveChoicesButtonLabel:
          json['saveChoicesButtonLabel'] as String? ?? 'Save Choices',
      preferenceModalButtons: json['preferenceModalButtons'] != null
          ? BannerButtons.fromJson(
              json['preferenceModalButtons'] as Map<String, dynamic>)
          : null,
      preferenceModalButtonStyles: json['preferenceModalButtonStyles'] != null
          ? BannerButtonsStyles.fromJson(
              json['preferenceModalButtonStyles'] as Map<String, dynamic>)
          : null,
      preferenceModalButtonOrder:
          (json['preferenceModalButtonOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      preferenceModalDenyButtonLabel:
          json['preferenceModalDenyButtonLabel'] as String?,
      preferenceModalSaveChoicesButtonLabel:
          json['preferenceModalSaveChoicesButtonLabel'] as String?,
      preferenceModalAllowAllButtonLabel:
          json['preferenceModalAllowAllButtonLabel'] as String?,
      aboutSectionContent: json['aboutSectionContent'] as String? ?? '',
      backgroundColor: json['backgroundColor'] as String? ?? '#ffffff',
      fontColor: json['fontColor'] as String? ?? '#000000',
      textSize: json['textSize'] as String? ?? 'medium',
      fontFamily: json['fontFamily'] as String? ?? 'Poppins',
      cookiePolicyUrl: json['cookiePolicyUrl'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      logoSize: json['logoSize'] != null
          ? LogoSize.fromJson(json['logoSize'] as Map<String, dynamic>)
          : const LogoSize(width: '100px', height: '100px'),
      colorScheme: json['colorScheme'] as String? ?? '#1032CF',
      buttonColor: json['buttonColor'] as String? ?? '#1032CF',
      showLogo: json['showLogo'] as String? ?? 'false',
      layoutType: json['layoutType'] as String? ?? 'footer',
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
      showLanguageDropdown: json['showLanguageDropdown'] as bool? ?? false,
      automaticLanguageDetection:
          json['automaticLanguageDetection'] as bool? ?? false,
      defaultOptIn: json['defaultOptIn'] as bool? ?? false,
      allowBannerClose: json['allowBannerClose'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consentTabHeading': consentTabHeading,
      'detailsTabHeading': detailsTabHeading,
      'aboutTabHeading': aboutTabHeading,
      'bannerHeading': bannerHeading,
      'bannerDescription': bannerDescription,
      if (detailsTabDescription != null)
        'detailsTabDescription': detailsTabDescription,
      if (buttons != null) 'buttons': buttons!.toJson(),
      if (buttonStyles != null) 'buttonStyles': buttonStyles!.toJson(),
      if (buttonOrder != null) 'buttonOrder': buttonOrder,
      'denyButtonLabel': denyButtonLabel,
      'allowSelectionButtonLabel': allowSelectionButtonLabel,
      'allowAllButtonLabel': allowAllButtonLabel,
      'saveChoicesButtonLabel': saveChoicesButtonLabel,
      if (preferenceModalButtons != null)
        'preferenceModalButtons': preferenceModalButtons!.toJson(),
      if (preferenceModalButtonStyles != null)
        'preferenceModalButtonStyles': preferenceModalButtonStyles!.toJson(),
      if (preferenceModalButtonOrder != null)
        'preferenceModalButtonOrder': preferenceModalButtonOrder,
      if (preferenceModalDenyButtonLabel != null)
        'preferenceModalDenyButtonLabel': preferenceModalDenyButtonLabel,
      if (preferenceModalSaveChoicesButtonLabel != null)
        'preferenceModalSaveChoicesButtonLabel':
            preferenceModalSaveChoicesButtonLabel,
      if (preferenceModalAllowAllButtonLabel != null)
        'preferenceModalAllowAllButtonLabel':
            preferenceModalAllowAllButtonLabel,
      'aboutSectionContent': aboutSectionContent,
      'backgroundColor': backgroundColor,
      'fontColor': fontColor,
      'textSize': textSize,
      'fontFamily': fontFamily,
      'cookiePolicyUrl': cookiePolicyUrl,
      'logoUrl': logoUrl,
      'logoSize': logoSize.toJson(),
      'colorScheme': colorScheme,
      'buttonColor': buttonColor,
      'showLogo': showLogo,
      'layoutType': layoutType,
      if (privacyPolicyUrl != null) 'privacyPolicyUrl': privacyPolicyUrl,
      'showLanguageDropdown': showLanguageDropdown,
      'automaticLanguageDetection': automaticLanguageDetection,
      'defaultOptIn': defaultOptIn,
      'allowBannerClose': allowBannerClose,
    };
  }
}

class BannerButtons {
  final bool deny;
  final bool allowSelection;
  final bool allowAll;

  const BannerButtons({
    required this.deny,
    required this.allowSelection,
    required this.allowAll,
  });

  factory BannerButtons.fromJson(Map<String, dynamic> json) {
    return BannerButtons(
      deny: json['deny'] as bool? ?? true,
      allowSelection: json['allowSelection'] as bool? ?? true,
      allowAll: json['allowAll'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deny': deny,
      'allowSelection': allowSelection,
      'allowAll': allowAll,
    };
  }
}

class BannerButtonsStyles {
  // Add button style properties if needed
  const BannerButtonsStyles();

  factory BannerButtonsStyles.fromJson(Map<String, dynamic> json) {
    return const BannerButtonsStyles();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}

class LogoSize {
  final String width;
  final String height;

  const LogoSize({
    required this.width,
    required this.height,
  });

  factory LogoSize.fromJson(Map<String, dynamic> json) {
    return LogoSize(
      width: json['width'] as String? ?? '100px',
      height: json['height'] as String? ?? '100px',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }
}

class BannerConfigurations {
  final BannerDesign bannerDesign;

  const BannerConfigurations({
    required this.bannerDesign,
  });

  factory BannerConfigurations.fromJson(Map<String, dynamic> json) {
    return BannerConfigurations(
      bannerDesign: BannerDesign.fromJson(
          json['bannerDesign'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bannerDesign': bannerDesign.toJson(),
    };
  }
}
