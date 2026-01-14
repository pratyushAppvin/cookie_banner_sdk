import 'package:flutter/material.dart';

/// Draggable floating logo that reopens cookie preferences
class FloatingLogo extends StatefulWidget {
  final String logoUrl;
  final double width;
  final double height;
  final VoidCallback onTap;
  final Offset? initialPosition;

  const FloatingLogo({
    super.key,
    required this.logoUrl,
    required this.width,
    required this.height,
    required this.onTap,
    this.initialPosition,
  });

  @override
  State<FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<FloatingLogo> {
  late Offset _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Default to bottom-right corner if no initial position
    _position = widget.initialPosition ?? const Offset(0, 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set default position after we have MediaQuery
    if (widget.initialPosition == null) {
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding; // Safe area insets
      
      // Calculate usable screen area (excluding system UI)
      final usableHeight = size.height - padding.top - padding.bottom;
      
      // Position in bottom-right, accounting for safe areas
      _position = Offset(
        size.width - widget.width - 16,
        usableHeight - widget.height - 80, // Use usable height, not full screen height
      );
      // print('🎯 FloatingLogo positioned at: (${_position.dx}, ${_position.dy})');
      // print('   Screen size: ${size.width} x ${size.height}');
      // print('   Safe area padding: top=${padding.top}, bottom=${padding.bottom}');
      // print('   Usable height: $usableHeight');
      // print('   Logo size: ${widget.width} x ${widget.height}');
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;

      // Snap to edges if close
      final size = MediaQuery.of(context).size;
      final screenWidth = size.width;
      final screenHeight = size.height;

      // Keep within bounds
      double x = _position.dx.clamp(0, screenWidth - widget.width);
      double y = _position.dy.clamp(0, screenHeight - widget.height);

      // Snap to nearest edge (left or right)
      if (x < screenWidth / 2) {
        x = 16; // Snap to left with padding
      } else {
        x = screenWidth - widget.width - 16; // Snap to right with padding
      }

      _position = Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('🎨 FloatingLogo building at position: (${_position.dx}, ${_position.dy})');
    // print('   Logo URL: ${widget.logoUrl}');
    // print('   Size: ${widget.width} x ${widget.height}');
    
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _isDragging ? null : widget.onTap,
        child: AnimatedContainer(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Material(
            elevation: _isDragging ? 12 : 8,
            shadowColor: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.network(
                widget.logoUrl,
                width: widget.width - 16,
                height: widget.height - 16,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.cookie,
                    size: (widget.width - 16).clamp(24, 48),
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
