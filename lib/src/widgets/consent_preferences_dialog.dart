import 'package:flutter/material.dart';
import '../models/user_data_properties.dart';
import '../models/cookie_properties.dart';

/// Dialog that displays detailed consent preferences with category and per-cookie toggles
class ConsentPreferencesDialog extends StatefulWidget {
  final UserDataProperties userData;
  final Map<int, bool> initialCategoryConsent;
  final Map<int, bool> initialCookieConsent;
  final VoidCallback? onSave;
  final ValueChanged<Map<int, bool>>? onCategoryConsentChanged;
  final ValueChanged<Map<int, bool>>? onCookieConsentChanged;

  const ConsentPreferencesDialog({
    super.key,
    required this.userData,
    required this.initialCategoryConsent,
    required this.initialCookieConsent,
    this.onSave,
    this.onCategoryConsentChanged,
    this.onCookieConsentChanged,
  });

  @override
  State<ConsentPreferencesDialog> createState() =>
      _ConsentPreferencesDialogState();
}

class _ConsentPreferencesDialogState extends State<ConsentPreferencesDialog> {
  late Map<int, bool> _categoryConsent;
  late Map<int, bool> _cookieConsent;
  late Map<int, bool> _expandedCategories;

  @override
  void initState() {
    super.initState();
    _categoryConsent = Map.from(widget.initialCategoryConsent);
    _cookieConsent = Map.from(widget.initialCookieConsent);
    _expandedCategories = {};
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.blue;
    }
    final hexColor = colorString.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.blue;
  }

  void _onCategoryToggled(int categoryId, bool value, bool isNecessary) {
    if (isNecessary) return; // Cannot toggle necessary cookies

    setState(() {
      _categoryConsent[categoryId] = value;

      // Update all cookies in this category
      final category = widget.userData.categoryConsentRecord
          .firstWhere((cat) => cat.categoryId == categoryId);

      for (final service in category.services) {
        for (final cookie in service.cookies) {
          _cookieConsent[cookie.cookieId] = value;
        }
      }

      for (final cookie in category.independentCookies) {
        _cookieConsent[cookie.cookieId] = value;
      }
    });

    widget.onCategoryConsentChanged?.call(_categoryConsent);
    widget.onCookieConsentChanged?.call(_cookieConsent);
  }

  void _onCookieToggled(int cookieId, bool value, int categoryId) {
    setState(() {
      _cookieConsent[cookieId] = value;

      // Check if all cookies in category are now enabled/disabled
      final category = widget.userData.categoryConsentRecord
          .firstWhere((cat) => cat.categoryId == categoryId);

      final allCookies = <CookieProperties>[
        ...category.services.expand((s) => s.cookies),
        ...category.independentCookies,
      ];

      final allEnabled = allCookies.every((c) => _cookieConsent[c.cookieId] == true);
      final allDisabled = allCookies.every((c) => _cookieConsent[c.cookieId] == false);

      if (allEnabled) {
        _categoryConsent[categoryId] = true;
      } else if (allDisabled) {
        _categoryConsent[categoryId] = false;
      }
    });

    widget.onCookieConsentChanged?.call(_cookieConsent);
    widget.onCategoryConsentChanged?.call(_categoryConsent);
  }

  @override
  Widget build(BuildContext context) {
    final design = widget.userData.bannerConfiguration.bannerDesign;
    final backgroundColor = _parseColor(design.backgroundColor);
    final fontColor = _parseColor(design.fontColor);
    final buttonColor = _parseColor(design.colorScheme);

    return Dialog(
      backgroundColor: backgroundColor,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: fontColor.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      design.consentTabHeading,
                      style: TextStyle(
                        color: fontColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: fontColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Category list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.userData.categoryConsentRecord.length,
                itemBuilder: (context, index) {
                  final category = widget.userData.categoryConsentRecord[index];
                  final isExpanded =
                      _expandedCategories[category.categoryId] ?? false;
                  final categoryEnabled =
                      _categoryConsent[category.categoryId] ?? false;
                  final allCookies = <CookieProperties>[
                    ...category.services.expand((s) => s.cookies),
                    ...category.independentCookies,
                  ];

                  return Card(
                    color: backgroundColor,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        // Category header with toggle
                        ListTile(
                          title: Text(
                            category.categoryName,
                            style: TextStyle(
                              color: fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            category.categoryDescription,
                            style: TextStyle(
                              color: fontColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (category.categoryNecessary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: buttonColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Always Active',
                                    style: TextStyle(
                                      color: buttonColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                              if (allCookies.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: fontColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _expandedCategories[category.categoryId] =
                                          !isExpanded;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),

                        // Expanded cookie list
                        if (isExpanded && allCookies.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: fontColor.withOpacity(0.05),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Services with cookies
                                ...category.services.map((service) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (service.serviceName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            service.serviceName,
                                            style: TextStyle(
                                              color: fontColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ...service.cookies.map((cookie) {
                                        return _buildCookieItem(
                                          cookie,
                                          category.categoryId,
                                          category.categoryNecessary,
                                          fontColor,
                                          buttonColor,
                                        );
                                      }),
                                    ],
                                  );
                                }),

                                // Independent cookies
                                ...category.independentCookies.map((cookie) {
                                  return _buildCookieItem(
                                    cookie,
                                    category.categoryId,
                                    category.categoryNecessary,
                                    fontColor,
                                    buttonColor,
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Save button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: fontColor.withOpacity(0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave?.call();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    design.saveChoicesButtonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookieItem(
    CookieProperties cookie,
    int categoryId,
    bool isNecessaryCategory,
    Color fontColor,
    Color buttonColor,
  ) {
    final cookieEnabled = _cookieConsent[cookie.cookieId] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cookie.cookieKey,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (cookie.description.isNotEmpty)
                  Text(
                    cookie.description,
                    style: TextStyle(
                      color: fontColor.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                if (cookie.expiration.isNotEmpty)
                  Text(
                    'Expires: ${cookie.expiration}',
                    style: TextStyle(
                      color: fontColor.withOpacity(0.5),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (isNecessaryCategory)
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
    );
  }
}
