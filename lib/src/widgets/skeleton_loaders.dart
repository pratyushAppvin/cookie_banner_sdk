import 'package:flutter/material.dart';

/// Skeleton loader for wall banner while config is loading
class WallBannerLoader extends StatelessWidget {
  const WallBannerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  _shimmerBox(40, 40, borderRadius: 8),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(200, 20)),
                ],
              ),
            ),

            // Tab bar skeleton
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shimmerBox(80, 16),
                  _shimmerBox(80, 16),
                  _shimmerBox(80, 16),
                ],
              ),
            ),

            // Content skeleton
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(double.infinity, 16),
                    const SizedBox(height: 8),
                    _shimmerBox(double.infinity, 16),
                    const SizedBox(height: 8),
                    _shimmerBox(250, 16),
                    const SizedBox(height: 24),
                    ...List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _shimmerBox(150, 16)),
                                  _shimmerBox(80, 32, borderRadius: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _shimmerBox(double.infinity, 14),
                              const SizedBox(height: 4),
                              _shimmerBox(200, 14),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Buttons skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _shimmerBox(100, 40, borderRadius: 4),
                  const SizedBox(width: 8),
                  _shimmerBox(120, 40, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double borderRadius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loader for footer banner while config is loading
class FooterBannerLoader extends StatelessWidget {
  const FooterBannerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                _shimmerBox(200, 18),
                const SizedBox(height: 8),

                // Description skeleton
                _shimmerBox(double.infinity, 14),
                const SizedBox(height: 4),
                _shimmerBox(double.infinity, 14),
                const SizedBox(height: 4),
                _shimmerBox(250, 14),
                const SizedBox(height: 16),

                // Buttons skeleton
                Row(
                  children: [
                    Expanded(child: _shimmerBox(double.infinity, 44, borderRadius: 6)),
                    const SizedBox(width: 12),
                    Expanded(child: _shimmerBox(double.infinity, 44, borderRadius: 6)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double borderRadius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
