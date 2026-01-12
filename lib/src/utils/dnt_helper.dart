import 'dnt_helper_stub.dart'
    if (dart.library.html) 'dnt_helper_web.dart';

/// Helper class to detect Do Not Track settings
/// 
/// On web platforms, reads the browser's DNT setting.
/// On mobile/desktop, DNT can be optionally enforced via a flag.
class DntHelper {
  /// Checks if Do Not Track is enabled
  /// 
  /// Returns true if:
  /// - On web: navigator.doNotTrack is '1' or 'yes'
  /// - On mobile: respectDnt flag is true (host app decision)
  static bool isDntEnabled({bool respectDnt = false}) {
    // Try to detect DNT on web via conditional import
    final webDnt = isDntEnabledWeb();
    
    // Return true if either web DNT is enabled or mobile flag is set
    return webDnt || respectDnt;
  }
}
