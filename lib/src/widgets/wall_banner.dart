import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner_design.dart';
import '../models/user_data_properties.dart';
import '../models/cookie_properties.dart';
import '../models/language.dart';
import 'language_selector.dart';

/// Full-screen wall banner with tabbed navigation (Consent, Details, About)
class WallBanner extends StatefulWidget {
  final BannerDesign design;
  final UserDataProperties userData;
  final Map<int, bool> categoryConsent;
  final Map<int, bool> userConsent;
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;
  final VoidCallback? onAllowSelection;
  final VoidCallback? onClose;
  final ValueChanged<Map<int, bool>>? onCategoryConsentChanged;
  final ValueChanged<Map<int, bool>>? onCookieConsentChanged;
  final List<Language> availableLanguages;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageChanged;

  const WallBanner({
    super.key,
    required this.design,
    required this.userData,
    required this.categoryConsent,
    required this.userConsent,
    required this.onAcceptAll,
    required this.onRejectAll,
    this.onAllowSelection,
    this.onClose,
    this.onCategoryConsentChanged,
    this.onCookieConsentChanged,
    required this.availableLanguages,
    required this.selectedLanguageCode,
    required this.onLanguageChanged,
  });

  @override
  State<WallBanner> createState() => _WallBannerState();
}

class _WallBannerState extends State<WallBanner> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<int, bool> _localCategoryConsent;
  late Map<int, bool> _localCookieConsent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _localCategoryConsent = Map.from(widget.categoryConsent);
    _localCookieConsent = Map.from(widget.userConsent);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorString, Color fallback) {
    try {
      final hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return fallback;
  }

  void _onCategoryToggled(int categoryId, bool value, bool isNecessary) {
    if (isNecessary) return;

    setState(() {
      _localCategoryConsent[categoryId] = value;

      // Update all cookies in this category
      final category = widget.userData.categoryConsentRecord
          .firstWhere((cat) => cat.categoryId == categoryId);

      for (final service in category.services) {
        for (final cookie in service.cookies) {
          _localCookieConsent[cookie.cookieId] = value;
        }
      }

      for (final cookie in category.independentCookies) {
        _localCookieConsent[cookie.cookieId] = value;
      }
    });

    widget.onCategoryConsentChanged?.call(_localCategoryConsent);
    widget.onCookieConsentChanged?.call(_localCookieConsent);
  }

  void _onCookieToggled(int cookieId, bool value, int categoryId) {
    setState(() {
      _localCookieConsent[cookieId] = value;

      // Check if all cookies in category are now enabled/disabled
      final category = widget.userData.categoryConsentRecord
          .firstWhere((cat) => cat.categoryId == categoryId);

      final allCookies = <CookieProperties>[
        ...category.services.expand((s) => s.cookies),
        ...category.independentCookies,
      ];

      final allEnabled = allCookies.every((c) => _localCookieConsent[c.cookieId] == true);
      final allDisabled = allCookies.every((c) => _localCookieConsent[c.cookieId] == false);

      if (allEnabled) {
        _localCategoryConsent[categoryId] = true;
      } else if (allDisabled) {
        _localCategoryConsent[categoryId] = false;
      }
    });

    widget.onCookieConsentChanged?.call(_localCookieConsent);
    widget.onCategoryConsentChanged?.call(_localCategoryConsent);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _parseColor(widget.design.backgroundColor, Colors.white);
    final fontColor = _parseColor(widget.design.fontColor, Colors.black);
    final buttonColor = _parseColor(widget.design.colorScheme, const Color(0xFF1032CF));

    return Material(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header with logo and close button
            _buildHeader(backgroundColor, fontColor, buttonColor),

            // Tab bar
            _buildTabBar(fontColor, buttonColor),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConsentTab(fontColor, buttonColor),
                  _buildDetailsTab(fontColor, buttonColor),
                  _buildAboutTab(fontColor),
                ],
              ),
            ),

            // Action buttons
            _buildActionButtons(backgroundColor, fontColor, buttonColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color backgroundColor, Color fontColor, Color buttonColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: fontColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          if (widget.design.showLogo == 'true' && widget.design.logoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.network(
                widget.design.logoUrl,
                width: double.tryParse(widget.design.logoSize.width.replaceAll('px', '')) ?? 40,
                height: double.tryParse(widget.design.logoSize.height.replaceAll('px', '')) ?? 40,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),

          // Title
          Expanded(
            child: Text(
              widget.design.bannerHeading,
              style: TextStyle(
                color: fontColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: widget.design.fontFamily,
              ),
            ),
          ),

          // Language selector
          if (widget.design.showLanguageDropdown && widget.availableLanguages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LanguageSelector(
                languages: widget.availableLanguages,
                selectedLanguageCode: widget.selectedLanguageCode,
                onLanguageChanged: widget.onLanguageChanged,
                textColor: fontColor,
                dropdownColor: backgroundColor,
              ),
            ),

          // Close button (follows Reject All functionality)
          if (widget.design.allowBannerClose)
            IconButton(
              icon: Icon(Icons.close, color: fontColor),
              onPressed: widget.onRejectAll,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color fontColor, Color buttonColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: fontColor.withOpacity(0.1)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: buttonColor,
        unselectedLabelColor: fontColor.withOpacity(0.6),
        indicatorColor: buttonColor,
        labelStyle: TextStyle(
          fontFamily: widget.design.fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: widget.design.consentTabHeading),
          Tab(text: widget.design.detailsTabHeading),
          Tab(text: widget.design.aboutTabHeading),
        ],
      ),
    );
  }

  Widget _buildConsentTab(Color fontColor, Color buttonColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner description
          Text(
            widget.design.bannerDescription,
            style: TextStyle(
              color: fontColor,
              fontSize: 14,
              fontFamily: widget.design.fontFamily,
            ),
          ),
          const SizedBox(height: 24),

          // Category toggles
          ...widget.userData.categoryConsentRecord.map((category) {
            final categoryEnabled = _localCategoryConsent[category.categoryId] ?? false;

            return Card(
              color: fontColor.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryName,
                            style: TextStyle(
                              color: fontColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: widget.design.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.categoryDescription,
                            style: TextStyle(
                              color: fontColor.withOpacity(0.7),
                              fontSize: 13,
                              fontFamily: widget.design.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category.categoryNecessary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: buttonColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Always Active',
                          style: TextStyle(
                            color: buttonColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: widget.design.fontFamily,
                          ),
                        ),
                      )
                    else
                      Switch(
                        value: categoryEnabled,
                        onChanged: (value) => _onCategoryToggled(
                          category.categoryId,
                          value,
                          category.categoryNecessary,
                        ),
                        activeColor: buttonColor,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Color fontColor, Color buttonColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details description if provided
          if (widget.design.detailsTabDescription?.isNotEmpty ?? false) ...[
            Text(
              widget.design.detailsTabDescription!,
              style: TextStyle(
                color: fontColor,
                fontSize: 14,
                fontFamily: widget.design.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Categories with full cookie details
          ...widget.userData.categoryConsentRecord.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.categoryName,
                          style: TextStyle(
                            color: fontColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: widget.design.fontFamily,
                          ),
                        ),
                      ),
                      if (category.categoryNecessary)
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: fontColor.withOpacity(0.5),
                        ),
                    ],
                  ),
                ),

                // Services
                ...category.services.map((service) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service.serviceName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 12, bottom: 8),
                          child: Text(
                            service.serviceName,
                            style: TextStyle(
                              color: fontColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: widget.design.fontFamily,
                            ),
                          ),
                        ),
                      if (service.serviceDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            service.serviceDescription,
                            style: TextStyle(
                              color: fontColor.withOpacity(0.7),
                              fontSize: 12,
                              fontFamily: widget.design.fontFamily,
                            ),
                          ),
                        ),
                      ...service.cookies.map((cookie) => _buildCookieDetail(
                            cookie,
                            category.categoryId,
                            category.categoryNecessary,
                            fontColor,
                            buttonColor,
                          )),
                    ],
                  );
                }),

                // Independent cookies
                ...category.independentCookies.map((cookie) => _buildCookieDetail(
                      cookie,
                      category.categoryId,
                      category.categoryNecessary,
                      fontColor,
                      buttonColor,
                    )),

                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCookieDetail(
    CookieProperties cookie,
    int categoryId,
    bool isNecessary,
    Color fontColor,
    Color buttonColor,
  ) {
    final cookieEnabled = _localCookieConsent[cookie.cookieId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cookie.cookieKey,
                    style: TextStyle(
                      color: fontColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: widget.design.fontFamily,
                    ),
                  ),
                  if (cookie.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      cookie.description,
                      style: TextStyle(
                        color: fontColor.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: widget.design.fontFamily,
                      ),
                    ),
                  ],
                  if (cookie.expiration.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: fontColor.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expires: ${cookie.expiration}',
                          style: TextStyle(
                            color: fontColor.withOpacity(0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            fontFamily: widget.design.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (cookie.vendorName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Provider: ${cookie.vendorName}',
                      style: TextStyle(
                        color: fontColor.withOpacity(0.6),
                        fontSize: 11,
                        fontFamily: widget.design.fontFamily,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isNecessary)
              Icon(
                Icons.lock,
                size: 16,
                color: fontColor.withOpacity(0.3),
              )
            else
              Switch(
                value: cookieEnabled,
                onChanged: (value) => _onCookieToggled(
                  cookie.cookieId,
                  value,
                  categoryId,
                ),
                activeColor: buttonColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Color fontColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section content (supports markdown)
          MarkdownBody(
            data: widget.design.aboutSectionContent,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: fontColor,
                fontSize: 14,
                fontFamily: widget.design.fontFamily,
              ),
              h1: TextStyle(
                color: fontColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: widget.design.fontFamily,
              ),
              h2: TextStyle(
                color: fontColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: widget.design.fontFamily,
              ),
              a: TextStyle(
                color: _parseColor(widget.design.colorScheme, const Color(0xFF1032CF)),
                decoration: TextDecoration.underline,
              ),
            ),
            onTapLink: (text, url, title) {
              if (url != null) {
                launchUrl(Uri.parse(url));
              }
            },
          ),

          const SizedBox(height: 24),

          // Privacy Policy and Cookie Policy links
          if (widget.design.privacyPolicyUrl?.isNotEmpty ?? false)
            _buildLink(
              'Privacy Policy',
              widget.design.privacyPolicyUrl!,
              fontColor,
            ),

          if (widget.design.cookiePolicyUrl.isNotEmpty)
            _buildLink(
              'Cookie Policy',
              widget.design.cookiePolicyUrl,
              fontColor,
            ),
        ],
      ),
    );
  }

  Widget _buildLink(String text, String url, Color fontColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Row(
          children: [
            Icon(
              Icons.open_in_new,
              size: 16,
              color: _parseColor(widget.design.colorScheme, const Color(0xFF1032CF)),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: _parseColor(widget.design.colorScheme, const Color(0xFF1032CF)),
                fontSize: 14,
                decoration: TextDecoration.underline,
                fontFamily: widget.design.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color backgroundColor, Color fontColor, Color buttonColor) {
    final buttonsCfg = widget.design.buttons ?? BannerButtons(deny: true, allowSelection: true, allowAll: true);
    final buttonOrder = widget.design.buttonOrder ?? ['deny', 'allowSelection', 'allowAll'];

    // Count visible buttons
    final visibleButtons = <String>[];
    if (buttonsCfg.deny) visibleButtons.add('deny');
    if (buttonsCfg.allowSelection && widget.onAllowSelection != null) visibleButtons.add('allowSelection');
    if (buttonsCfg.allowAll) visibleButtons.add('allowAll');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: fontColor.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: buttonOrder.where((type) => visibleButtons.contains(type)).map((buttonType) {
          final isLast = buttonType == buttonOrder.where((t) => visibleButtons.contains(t)).last;
          
          Widget button;
          switch (buttonType) {
            case 'deny':
              button = OutlinedButton(
                onPressed: widget.onRejectAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: buttonColor,
                  side: BorderSide(color: buttonColor, width: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.design.denyButtonLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: widget.design.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
              break;

            case 'allowSelection':
              button = OutlinedButton(
                onPressed: widget.onAllowSelection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: fontColor,
                  side: BorderSide(color: fontColor.withOpacity(0.5), width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.design.allowSelectionButtonLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: widget.design.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
              break;

            case 'allowAll':
              button = ElevatedButton(
                onPressed: widget.onAcceptAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.design.allowAllButtonLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: widget.design.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
              break;

            default:
              button = const SizedBox.shrink();
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: button,
            ),
          );
        }).toList(),
      ),
    );
  }
}
