// Web-specific implementation of DNT detection
import 'dart:html' as html;

bool isDntEnabledWeb() {
  final navigatorDnt = html.window.navigator.doNotTrack;
  return navigatorDnt == '1' || navigatorDnt == 'yes';
}
