import 'package:flutter/material.dart';
import '../models/banner_design.dart';
import '../models/language.dart';
import 'language_selector.dart';

/// Simple footer banner widget with Accept/Reject/Allow Selection buttons.
///
/// Displays a fixed bottom banner with banner title, description,
/// and action buttons. Respects safe areas on mobile devices.
class FooterBanner extends StatelessWidget {
  final BannerDesign design;
  final String title;
  final String description;
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;
  final VoidCallback? onAllowSelection;
  final List<Language> availableLanguages;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageChanged;

  const FooterBanner({
    super.key,
    required this.design,
    required this.title,
    required this.description,
    required this.onAcceptAll,
    required this.onRejectAll,
    this.onAllowSelection,
    required this.availableLanguages,
    required this.selectedLanguageCode,
    required this.onLanguageChanged,
  });

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

  double _getTextSize(String size) {
    switch (size.toLowerCase()) {
      case 'small':
        return 12.0;
      case 'large':
        return 18.0;
      case 'medium':
      default:
        return 14.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final backgroundColor = _parseColor(design.backgroundColor, Colors.white);
    final textColor = _parseColor(design.fontColor, Colors.black);
    final buttonColor = _parseColor(design.colorScheme, const Color(0xFF1032CF));
    final textSize = _getTextSize(design.textSize);

    // Check which buttons to show
    final showDeny = design.buttons?.deny ?? true;
    final showAllowAll = design.buttons?.allowAll ?? true;
    final showAllowSelection = design.buttons?.allowSelection ?? true;
    
    // Get button order
    final buttonOrder = design.buttonOrder ?? ['deny', 'allowSelection', 'allowAll'];

    return Material(
      elevation: 8,
      color: backgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + (bottomPadding > 0 ? 0 : 8),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with logo and language selector
                if (design.showLogo == 'true' && design.logoUrl.isNotEmpty || 
                    design.showLanguageDropdown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Logo
                        if (design.showLogo == 'true' && design.logoUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Image.network(
                              design.logoUrl,
                              width: double.tryParse(design.logoSize.width.replaceAll('px', '')) ?? 50,
                              height: double.tryParse(design.logoSize.height.replaceAll('px', '')) ?? 50,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                        const Spacer(),
                        // Language selector
                        if (design.showLanguageDropdown && availableLanguages.isNotEmpty)
                          LanguageSelector(
                            languages: availableLanguages,
                            selectedLanguageCode: selectedLanguageCode,
                            onLanguageChanged: onLanguageChanged,
                            textColor: textColor,
                            dropdownColor: backgroundColor,
                          ),
                        if (design.showLanguageDropdown && availableLanguages.isNotEmpty && design.allowBannerClose)
                          const SizedBox(width: 10),
                        // Close button (follows Reject All functionality)
                        if (design.allowBannerClose)
                          IconButton(
                            onPressed: onRejectAll,
                            icon: Icon(
                              Icons.close,
                              color: textColor,
                              size: 24,
                            ),
                            tooltip: 'Close',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),

                // Title
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: textSize + 4,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: design.fontFamily,
                    ),
                  ),
                
                if (title.isNotEmpty) const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: textSize,
                    color: textColor,
                    fontFamily: design.fontFamily,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Buttons in configured order
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: buttonOrder.map((buttonType) {
                    switch (buttonType) {
                      case 'deny':
                        if (!showDeny) return const SizedBox.shrink();
                        return SizedBox(
                          width: buttonOrder.length == 1 ? double.infinity : null,
                          child: OutlinedButton(
                            onPressed: onRejectAll,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: buttonColor,
                              side: BorderSide(color: buttonColor, width: 2),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              design.denyButtonLabel,
                              style: TextStyle(
                                fontFamily: design.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      
                      case 'allowSelection':
                        if (!showAllowSelection || onAllowSelection == null) {
                          return const SizedBox.shrink();
                        }
                        return SizedBox(
                          width: buttonOrder.length == 1 ? double.infinity : null,
                          child: OutlinedButton(
                            onPressed: onAllowSelection,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: textColor.withOpacity(0.5), width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              design.allowSelectionButtonLabel,
                              style: TextStyle(
                                fontFamily: design.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      
                      case 'allowAll':
                        if (!showAllowAll) return const SizedBox.shrink();
                        return SizedBox(
                          width: buttonOrder.length == 1 ? double.infinity : null,
                          child: ElevatedButton(
                            onPressed: onAcceptAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              design.allowAllButtonLabel,
                              style: TextStyle(
                                fontFamily: design.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      
                      default:
                        return const SizedBox.shrink();
                    }
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
