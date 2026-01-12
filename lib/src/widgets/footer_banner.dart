import 'package:flutter/material.dart';
import '../models/banner_design.dart';

/// Simple footer banner widget with Accept/Reject buttons.
///
/// Displays a fixed bottom banner with banner title, description,
/// and action buttons. Respects safe areas on mobile devices.
class FooterBanner extends StatelessWidget {
  final BannerDesign design;
  final String title;
  final String description;
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;

  const FooterBanner({
    super.key,
    required this.design,
    required this.title,
    required this.description,
    required this.onAcceptAll,
    required this.onRejectAll,
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

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
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
                
                // Buttons
                Row(
                  children: [
                    if (showDeny) ...[
                      Expanded(
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
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    if (showAllowAll)
                      Expanded(
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
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
