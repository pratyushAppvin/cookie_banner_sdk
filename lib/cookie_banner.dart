import 'package:flutter/material.dart';
import 'src/models/models.dart';
import 'src/services/consent_storage.dart';
import 'src/services/shared_preferences_consent_storage.dart';
import 'src/services/cookie_banner_api_client.dart';
import 'src/utils/uuid_helper.dart';
import 'src/utils/consent_helpers.dart';
import 'src/widgets/footer_banner.dart';

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

  /// Callback fired when consent changes
  final ValueChanged<Map<int, bool>>? onConsentChanged;

  /// Callback fired when user accepts all cookies
  final VoidCallback? onAcceptAll;

  /// Callback fired when user rejects all cookies
  final VoidCallback? onRejectAll;

  const CookieBanner({
    super.key,
    required this.domainUrl,
    required this.environment,
    this.domainId,
    this.overrideDesign,
    this.onConsentChanged,
    this.onAcceptAll,
    this.onRejectAll,
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
  bool _isVisible = false;
  bool _isLoading = true;
  Map<int, bool> _categoryConsent = {};
  
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
    try {
      // 1. Generate or load subject identity (UUID)
      await _loadOrGenerateSubjectIdentity();

      // 2. Load stored consent
      _storedConsent = await _storage.loadConsent();

      // 3. Fetch geolocation
      await _fetchGeolocation();

      // 4. Fetch banner configuration
      await _fetchBannerConfig();

      // 5. Decide whether to show banner
      final needsConsent = ConsentHelpers.needsReconsent(
        storedSnapshot: _storedConsent,
        currentData: _userData,
      );

      // 6. Initialize category consent
      _categoryConsent = ConsentHelpers.initializeCategoryConsent(
        storedSnapshot: _storedConsent,
        userData: _userData,
      );

      setState(() {
        _isVisible = needsConsent;
        _isLoading = false;
      });
    } catch (e) {
      print('Cookie banner initialization error: $e');
      setState(() {
        _isLoading = false;
        _isVisible = false; // Hide on error
      });
    }
  }

  Future<void> _loadOrGenerateSubjectIdentity() async {
    if (_storedConsent != null) {
      _subjectIdentity = _storedConsent!.subjectIdentity;
    } else {
      _subjectIdentity = UuidHelper.generateV4();
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
      // Try CDN first
      final dataList = await _apiClient.fetchBannerDataFromCdn(
        domainUrl: widget.domainUrl,
        domainId: domainId,
      );

      if (dataList.isNotEmpty) {
        _userData = dataList.first; // Use first language variant
      }
    } catch (e) {
      print('CDN fetch failed, trying fallback: $e');

      try {
        // Fallback to API
        _userData = await _apiClient.fetchBannerDataFallback(
          domainId: domainId,
          subjectIdentity: _subjectIdentity!,
          countryName: _countryName,
        );
      } catch (e) {
        print('Fallback API fetch failed: $e');
      }
    }
  }

  Future<void> _handleAcceptAll() async {
    if (_userData == null) return;

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
    });
  }

  Future<void> _handleRejectAll() async {
    if (_userData == null) return;

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
    });
  }

  Future<void> _saveConsent(Map<int, bool> consent) async {
    if (_userData == null || _subjectIdentity == null) return;

    // Build consent snapshot
    final snapshot = ConsentHelpers.buildConsentSnapshot(
      subjectIdentity: _subjectIdentity!,
      domainId: widget.domainId ?? 0,
      domainUrl: widget.domainUrl,
      userData: _userData,
      consentsByCategory: consent,
    );

    // Save to storage
    await _storage.saveConsent(snapshot);

    // Build API consent payload
    final cookieConsents = <CookieConsent>[];
    for (final category in _userData!.categoryConsentRecord) {
      final categoryConsent = consent[category.categoryId] ?? false;
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
      );
    } catch (e) {
      print('Backend consent update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (!_isVisible || _userData == null) {
      return const SizedBox.shrink();
    }

    final design = widget.overrideDesign ?? 
                   _userData!.bannerConfiguration.bannerDesign;

    return FooterBanner(
      design: design,
      title: _userData!.bannerTitle,
      description: _userData!.bannerDescription,
      onAcceptAll: _handleAcceptAll,
      onRejectAll: _handleRejectAll,
    );
  }
}
