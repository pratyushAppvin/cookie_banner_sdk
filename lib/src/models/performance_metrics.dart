/// Performance metrics for banner loading and user interaction.
///
/// Tracks timing data to measure SDK performance and user experience.
class PerformanceMetrics {
  final int? cdnResponseTime;
  final int? apiResponseTime;
  final int? totalLoadTime;
  final int? bannerDisplayTime;
  final int? userReactionTime;
  final String loadMethod; // 'cdn' or 'api'
  
  const PerformanceMetrics({
    this.cdnResponseTime,
    this.apiResponseTime,
    this.totalLoadTime,
    this.bannerDisplayTime,
    this.userReactionTime,
    required this.loadMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      if (cdnResponseTime != null) 'cdn_response_time': cdnResponseTime,
      if (apiResponseTime != null) 'api_response_time': apiResponseTime,
      if (totalLoadTime != null) 'total_load_time': totalLoadTime,
      if (bannerDisplayTime != null) 'banner_display_time': bannerDisplayTime,
      if (userReactionTime != null) 'user_reaction_time': userReactionTime,
      'load_method': loadMethod,
    };
  }
}

/// Builder class for collecting performance metrics throughout the banner lifecycle.
class PerformanceMetricsBuilder {
  DateTime? _startTime;
  DateTime? _cdnStartTime;
  DateTime? _cdnEndTime;
  DateTime? _apiStartTime;
  DateTime? _apiEndTime;
  DateTime? _bannerDisplayTime;
  DateTime? _userInteractionTime;
  String _loadMethod = 'cdn';

  /// Mark the start of the overall loading process
  void markStart() {
    _startTime = DateTime.now();
  }

  /// Mark the start of CDN fetch
  void markCdnStart() {
    _cdnStartTime = DateTime.now();
  }

  /// Mark the end of CDN fetch
  void markCdnEnd({bool success = true}) {
    _cdnEndTime = DateTime.now();
    if (success) {
      _loadMethod = 'cdn';
    }
  }

  /// Mark the start of API fetch
  void markApiStart() {
    _apiStartTime = DateTime.now();
  }

  /// Mark the end of API fetch
  void markApiEnd() {
    _apiEndTime = DateTime.now();
    _loadMethod = 'api';
  }

  /// Mark when the banner is displayed to the user
  void markBannerDisplayed() {
    _bannerDisplayTime = DateTime.now();
  }

  /// Mark when the user interacts with the banner
  void markUserInteraction() {
    _userInteractionTime = DateTime.now();
  }

  /// Build the final metrics object
  PerformanceMetrics build() {
    int? cdnTime;
    if (_cdnStartTime != null && _cdnEndTime != null) {
      cdnTime = _cdnEndTime!.difference(_cdnStartTime!).inMilliseconds;
    }

    int? apiTime;
    if (_apiStartTime != null && _apiEndTime != null) {
      apiTime = _apiEndTime!.difference(_apiStartTime!).inMilliseconds;
    }

    int? totalTime;
    if (_startTime != null && _bannerDisplayTime != null) {
      totalTime = _bannerDisplayTime!.difference(_startTime!).inMilliseconds;
    }

    int? displayTime;
    if (_bannerDisplayTime != null) {
      displayTime = DateTime.now().difference(_bannerDisplayTime!).inMilliseconds;
    }

    int? reactionTime;
    if (_bannerDisplayTime != null && _userInteractionTime != null) {
      reactionTime = _userInteractionTime!.difference(_bannerDisplayTime!).inMilliseconds;
    }

    return PerformanceMetrics(
      cdnResponseTime: cdnTime,
      apiResponseTime: apiTime,
      totalLoadTime: totalTime,
      bannerDisplayTime: displayTime,
      userReactionTime: reactionTime,
      loadMethod: _loadMethod,
    );
  }

  /// Reset all metrics
  void reset() {
    _startTime = null;
    _cdnStartTime = null;
    _cdnEndTime = null;
    _apiStartTime = null;
    _apiEndTime = null;
    _bannerDisplayTime = null;
    _userInteractionTime = null;
    _loadMethod = 'cdn';
  }
}
