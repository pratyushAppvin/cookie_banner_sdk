import 'package:flutter/material.dart';
import 'src/models/models.dart';
import 'src/services/consent_storage.dart';
import 'src/services/shared_preferences_consent_storage.dart';
import 'src/services/cookie_banner_api_client.dart';
import 'src/services/device_info_collector.dart';
import 'src/utils/uuid_helper.dart';
import 'src/utils/consent_helpers.dart';
import 'src/utils/dnt_helper.dart';
import 'src/widgets/footer_banner.dart';
import 'src/widgets/wall_banner.dart';
import 'src/widgets/floating_logo.dart';
import 'src/widgets/skeleton_loaders.dart';
import 'src/widgets/consent_preferences_dialog.dart';

/// Main cookie banner widget for GDPR/CCPA compliance.
///
/// This widget provides a dynamic, configurable cookie consent banner
/// that can be embedded in any Flutter app. All configuration is provided
/// via constructor parameters, keeping the SDK fully dynamic.
class CookieBanner extends StatefulWidget {
  /// Domain URL for which cookies are being managed
  final String domainUrl;

  /// Base URL for backend API environment (dev/staging/prod)
  final String environment;

  /// Optional domain identifier
  final int? domainId;

  /// Optional override for banner design (bypasses remote config)
  final BannerDesign? overrideDesign;

  /// Whether to respect Do Not Track setting (mobile only, web auto-detects)
  final bool respectDnt;

  /// Callback fired when consent changes
  final ValueChanged<Map<int, bool>>? onConsentChanged;

  /// Callback fired when user accepts all cookies
  final VoidCallback? onAcceptAll;

  /// Callback fired when user rejects all cookies
  final VoidCallback? onRejectAll;

  /// Callback fired when an error occurs
  final ValueChanged<String>? onError;

  const CookieBanner({
    super.key,
    required this.domainUrl,
    required this.environment,
    this.domainId,
    this.overrideDesign,
    this.respectDnt = false,
    this.onConsentChanged,
    this.onAcceptAll,
    this.onRejectAll,
    this.onError,
  });

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner> {
  // Services
  late final ConsentStorage _storage;
  late final CookieBannerApiClient _apiClient;

  // State
  String? _subjectIdentity;
  ConsentSnapshot? _storedConsent;
  UserDataProperties? _userData;
  List<UserDataProperties>? _allLanguageData; // All language variants
  List<Language> _availableLanguages = [];
  String _selectedLanguageCode = 'en';
  bool _isVisible = false;
  bool _isLoading = true;
  Map<int, bool> _categoryConsent = {};
  Map<int, bool> _userConsent = {}; // Per-cookie consent tracking
  bool _showFloatingLogo = false;
  Offset? _logoPosition;
  DeviceInfo? _deviceInfo;
  
  // Performance tracking
  final PerformanceMetricsBuilder _performanceMetrics = PerformanceMetricsBuilder();
  
  // Geolocation
  String _ip = '';
  String _countryCode = '';
  String _countryName = '';
  String _continent = '';

  @override
  void initState() {
    super.initState();
    _storage = SharedPreferencesConsentStorage();
    _apiClient = CookieBannerApiClient(baseUrl: widget.environment);
    _initialize();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _performanceMetrics.markStart();
    
    try {
      // 1. Generate or load subject identity (UUID)
      await _loadOrGenerateSubjectIdentity();

      // 2. Load stored consent
      _storedConsent = await _storage.loadConsent();

      // 3. Collect device info
      if (mounted) {
        _deviceInfo = await DeviceInfoCollector.collectDeviceInfo(context);
      }

      // 4. Fetch geolocation
      await _fetchGeolocation();

      // 5. Fetch banner configuration (all languages)
      await _fetchBannerConfig();

      // 6. Fetch available languages
      await _fetchLanguages();
      print('🌐 Available languages fetched: ${_availableLanguages.length}');
      if (_availableLanguages.isNotEmpty) {
        print('   Languages: ${_availableLanguages.map((l) => l.languageCode).join(", ")}');
      }

      // 7. Auto-detect language if enabled
      _autoDetectLanguage();

      // 8. Set user data based on selected language
      _updateUserDataForLanguage();
      
      // Debug banner configuration
      final design = widget.overrideDesign ?? _userData?.bannerConfiguration.bannerDesign;
      if (design != null) {
        print('🎨 Banner Design Configuration:');
        print('   Layout Type: ${design.layoutType}');
        print('   Show Logo: "${design.showLogo}"');
        print('   Logo URL: "${design.logoUrl}"');
        print('   Show Language Dropdown: ${design.showLanguageDropdown}');
        print('   Allow Banner Close: ${design.allowBannerClose}');
      }

      // 9. Decide whether to show banner
      final needsConsent = ConsentHelpers.needsReconsent(
        storedSnapshot: _storedConsent,
        currentData: _userData,
      );

      // 10. Initialize category consent
      _categoryConsent = ConsentHelpers.initializeCategoryConsent(
        storedSnapshot: _storedConsent,
        userData: _userData,
      );

      // 11. Initialize per-cookie consent
      _initializeUserConsent();

      setState(() {
        _isVisible = needsConsent;
        _isLoading = false;
      });

      // 12. Mark banner as displayed and send metrics
      if (_isVisible && mounted) {
        _performanceMetrics.markBannerDisplayed();
        _sendPerformanceMetrics();
      }
    } catch (e) {
      print('Cookie banner initialization error: $e');
      setState(() {
        _isLoading = false;
        _isVisible = false; // Hide on error
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _loadOrGenerateSubjectIdentity() async {
    if (_storedConsent != null) {
      _subjectIdentity = _storedConsent!.subjectIdentity;
    } else {
      _subjectIdentity = UuidHelper.generateV4();
    }
  }

  void _initializeUserConsent() {
    if (_userData == null) return;

    // Initialize per-cookie consent based on category consent
    _userConsent.clear();
    
    for (final category in _userData!.categoryConsentRecord) {
      final categoryEnabled = _categoryConsent[category.categoryId] ?? category.categoryNecessary;
      
      // Set consent for all cookies in services
      for (final service in category.services) {
        for (final cookie in service.cookies) {
          _userConsent[cookie.cookieId] = categoryEnabled;
        }
      }
      
      // Set consent for independent cookies
      for (final cookie in category.independentCookies) {
        _userConsent[cookie.cookieId] = categoryEnabled;
      }
    }
  }

  Future<void> _fetchGeolocation() async {
    try {
      _ip = await _apiClient.fetchPublicIp();
      final geoInfo = await _apiClient.fetchIpInfo(ip: _ip);
      _countryCode = geoInfo.countryCode;
      _countryName = geoInfo.country;
      _continent = geoInfo.continent;
    } catch (e) {
      print('Geolocation fetch error: $e');
      // Use defaults
      _ip = '';
      _countryCode = 'US';
      _countryName = 'United States';
      _continent = 'North America';
    }
  }

  Future<void> _fetchBannerConfig() async {
    final domainId = widget.domainId ?? 0;

    try {
      // Try CDN first - gets all language variants
      _performanceMetrics.markCdnStart();
      
      _allLanguageData = await _apiClient.fetchBannerDataFromCdn(
        domainUrl: widget.domainUrl,
        domainId: domainId,
      );

      _performanceMetrics.markCdnEnd(success: true);

      if (_allLanguageData!.isNotEmpty) {
        _userData = _allLanguageData!.first; // Default to first language
      }
    } catch (e) {
      _performanceMetrics.markCdnEnd(success: false);
      print('CDN fetch failed, trying fallback: $e');

      try {
        // Fallback to API - gets single language
        _performanceMetrics.markApiStart();
        
        _userData = await _apiClient.fetchBannerDataFallback(
          domainId: domainId,
          subjectIdentity: _subjectIdentity!,
          countryName: _countryName,
        );
        
        _performanceMetrics.markApiEnd();
        _allLanguageData = [_userData!];
      } catch (e) {
        print('Fallback API fetch failed: $e');
        widget.onError?.call('Failed to load banner configuration');
      }
    }
  }

  Future<void> _fetchLanguages() async {
    final domainId = widget.domainId ?? 0;
    
    try {
      _availableLanguages = await _apiClient.fetchLanguages(domainId: domainId);
    } catch (e) {
      print('⚠️ Language fetch failed: $e');
      print('   This might require authentication. Language selector will be hidden.');
      _availableLanguages = [];
    }
  }

  void _autoDetectLanguage() {
    final design = widget.overrideDesign ?? _userData?.bannerConfiguration.bannerDesign;
    
    if (design?.automaticLanguageDetection != true) {
      return; // Auto-detection disabled
    }

    if (_availableLanguages.isEmpty || _allLanguageData == null) {
      return;
    }

    // Get device language code
    final deviceLanguageCode = DeviceInfoCollector.getDeviceLanguageCode();

    // Check if we have this language available
    final hasLanguage = _availableLanguages.any(
      (lang) => lang.languageCode == deviceLanguageCode,
    );

    if (hasLanguage) {
      _selectedLanguageCode = deviceLanguageCode;
    }
  }

  void _updateUserDataForLanguage() {
    if (_allLanguageData == null || _allLanguageData!.isEmpty) {
      return;
    }

    // Find data matching selected language code
    final matchingData = _allLanguageData!.firstWhere(
      (data) => data.languageCode == _selectedLanguageCode,
      orElse: () => _allLanguageData!.first,
    );

    _userData = matchingData;
  }

  Future<void> _sendPerformanceMetrics() async {
    if (_subjectIdentity == null) return;

    try {
      final metrics = _performanceMetrics.build();
      
      await _apiClient.sendLoadTimeMetrics(
        domainId: widget.domainId ?? 0,
        subjectIdentity: _subjectIdentity!,
        domainUrl: widget.domainUrl,
        cdnResponseTime: metrics.cdnResponseTime,
        apiResponseTime: metrics.apiResponseTime,
        totalLoadTime: metrics.totalLoadTime,
        bannerDisplayTime: metrics.bannerDisplayTime,
        userReactionTime: metrics.userReactionTime,
        loadMethod: metrics.loadMethod,
        deviceInfo: _deviceInfo != null ? DeviceInfoData.fromDeviceInfo(_deviceInfo!) : null,
      );
    } catch (e) {
      // Metrics are non-critical, just log
      print('Performance metrics send failed: $e');
    }
  }

  void _onLanguageChanged(String newLanguageCode) {
    setState(() {
      _selectedLanguageCode = newLanguageCode;
      _updateUserDataForLanguage();
      // Reinitialize consent with new language data
      _categoryConsent = ConsentHelpers.initializeCategoryConsent(
        storedSnapshot: _storedConsent,
        userData: _userData,
      );
      _initializeUserConsent();
    });
  }

  Future<void> _handleAcceptAll() async {
    if (_userData == null) return;

    _performanceMetrics.markUserInteraction();

    // Set all categories to true
    final allConsent = <int, bool>{};
    for (final category in _userData!.categoryConsentRecord) {
      allConsent[category.categoryId] = true;
    }

    await _saveConsent(allConsent);
    
    widget.onAcceptAll?.call();
    widget.onConsentChanged?.call(allConsent);

    setState(() {
      _isVisible = false;
      _showFloatingLogo = _shouldShowFloatingLogo();
    });
  }

  Future<void> _handleRejectAll() async {
    if (_userData == null) return;

    _performanceMetrics.markUserInteraction();

    // Set all non-necessary categories to false
    final minimalConsent = <int, bool>{};
    for (final category in _userData!.categoryConsentRecord) {
      minimalConsent[category.categoryId] = category.categoryNecessary;
    }

    await _saveConsent(minimalConsent);
    
    widget.onRejectAll?.call();
    widget.onConsentChanged?.call(minimalConsent);

    setState(() {
      _isVisible = false;
      _showFloatingLogo = _shouldShowFloatingLogo();
    });
  }

  Future<void> _handleAllowSelection() async {
    if (_userData == null || !mounted) return;

    _performanceMetrics.markUserInteraction();

    // Show the consent preferences dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ConsentPreferencesDialog(
          userData: _userData!,
          initialCategoryConsent: _categoryConsent,
          initialCookieConsent: _userConsent,
          onCategoryConsentChanged: (consent) {
            _categoryConsent = consent;
          },
          onCookieConsentChanged: (consent) {
            _userConsent = consent;
          },
          onSave: () async {
            // Save consent when user clicks Save button
            await _saveConsent(_categoryConsent);
            widget.onConsentChanged?.call(_categoryConsent);
            
            setState(() {
              _isVisible = false;
              _showFloatingLogo = _shouldShowFloatingLogo();
            });
          },
        );
      },
    );
  }

  Future<void> _saveConsent(Map<int, bool> consent) async {
    if (_userData == null || _subjectIdentity == null) return;

    // Apply DNT and necessary category enforcement
    final dntEnabled = DntHelper.isDntEnabled(respectDnt: widget.respectDnt);
    final effectiveConsent = ConsentHelpers.buildEffectiveConsent(
      rawConsent: consent,
      data: _userData,
      dntEnabled: dntEnabled,
    );

    // Build consent snapshot with effective consent
    final snapshot = ConsentHelpers.buildConsentSnapshot(
      subjectIdentity: _subjectIdentity!,
      domainId: widget.domainId ?? 0,
      domainUrl: widget.domainUrl,
      userData: _userData,
      consentsByCategory: effectiveConsent,
    );

    // Save to storage
    await _storage.saveConsent(snapshot);

    // Build API consent payload
    final cookieConsents = <CookieConsent>[];
    for (final category in _userData!.categoryConsentRecord) {
      final categoryConsent = effectiveConsent[category.categoryId] ?? false;
      for (final cookie in category.getAllCookies()) {
        cookieConsents.add(CookieConsent(
          categoryId: category.categoryId,
          consentRecordId: cookie.consentRecordId,
          consentStatus: category.categoryNecessary || categoryConsent,
          cookieId: cookie.cookieId,
          serviceId: cookie.serviceId,
        ));
      }
    }

    // Update backend
    try {
      await _apiClient.updateConsent(
        snapshot: snapshot,
        geolocation: '$_ip($_countryCode)',
        continent: _continent,
        country: _countryName,
        source: 'mobile',
        cookieCategoryConsent: cookieConsents,
        deviceInfo: _deviceInfo != null ? DeviceInfoData.fromDeviceInfo(_deviceInfo!) : null,
      );
    } catch (e) {
      print('Backend consent update failed: $e');
    }
  }

  bool _shouldShowFloatingLogo() {
    final design = widget.overrideDesign ?? _userData?.bannerConfiguration.bannerDesign;
    if (design == null) return false;
    
    return design.showLogo == 'true' && 
           design.logoUrl.isNotEmpty &&
           !_isVisible;
  }

  void _handleLogoTap() {
    setState(() {
      _isVisible = true;
      _showFloatingLogo = false;
    });
  }

  void _handleBannerClose() {
    // Close banner without saving (only if allowBannerClose is true)
    setState(() {
      _isVisible = false;
      _showFloatingLogo = _shouldShowFloatingLogo();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loader while initializing
    if (_isLoading) {
      // Show appropriate loader based on expected layout type
      // Default to footer loader if we don't have config yet
      return const FooterBannerLoader();
    }

    if (_userData == null) {
      return const SizedBox.shrink();
    }

    final design = widget.overrideDesign ?? 
                   _userData!.bannerConfiguration.bannerDesign;

    return Stack(
      children: [
        // Main banner (wall or footer based on layoutType) with animation
        if (_isVisible)
          Positioned(
            left: design.layoutType == 'wall' ? 0 : 0,
            right: design.layoutType == 'wall' ? 0 : 0,
            bottom: design.layoutType == 'wall' ? 0 : 0,
            top: design.layoutType == 'wall' ? 0 : null,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: design.layoutType == 'wall'
                  ? WallBanner(
                      design: design,
                      userData: _userData!,
                      categoryConsent: _categoryConsent,
                      userConsent: _userConsent,
                      onAcceptAll: _handleAcceptAll,
                      onRejectAll: _handleRejectAll,
                      onAllowSelection: _handleAllowSelection,
                      onClose: design.allowBannerClose ? _handleBannerClose : null,
                      onCategoryConsentChanged: (consent) {
                        setState(() {
                          _categoryConsent = consent;
                        });
                      },
                      onCookieConsentChanged: (consent) {
                        setState(() {
                          _userConsent = consent;
                        });
                      },
                      availableLanguages: _availableLanguages,
                      selectedLanguageCode: _selectedLanguageCode,
                      onLanguageChanged: _onLanguageChanged,
                    )
                  : FooterBanner(
                      design: design,
                      title: _userData!.bannerTitle,
                      description: _userData!.bannerDescription,
                      onAcceptAll: _handleAcceptAll,
                      onRejectAll: _handleRejectAll,
                      onAllowSelection: _handleAllowSelection,
                      availableLanguages: _availableLanguages,
                      selectedLanguageCode: _selectedLanguageCode,
                      onLanguageChanged: _onLanguageChanged,
                    ),
            ),
          ),

        // Floating logo (appears after banner is dismissed)
        if (_showFloatingLogo && design.showLogo == 'true' && design.logoUrl.isNotEmpty)
          FloatingLogo(
            logoUrl: design.logoUrl,
            width: double.tryParse(design.logoSize.width.replaceAll('px', '')) ?? 60,
            height: double.tryParse(design.logoSize.height.replaceAll('px', '')) ?? 60,
            onTap: _handleLogoTap,
            initialPosition: _logoPosition,
          ),
      ],
    );
  }
}

