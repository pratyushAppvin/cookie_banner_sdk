import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import '../models/device_info.dart';

/// Service to collect comprehensive device and platform information
class DeviceInfoCollector {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Collect all device information
  static Future<DeviceInfo?> collectDeviceInfo(BuildContext context) async {
    try {
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      final devicePixelRatio = mediaQuery.devicePixelRatio;
      final viewportWidth = screenWidth;
      final viewportHeight = screenHeight;

      String osName = 'Unknown';
      String osVersion = 'Unknown';
      String deviceType = 'Unknown';
      bool isMobile = false;
      bool isTablet = false;
      bool isDesktop = false;
      String? mobileVendor;
      String? mobileModel;
      String browserName = 'Flutter';
      String browserVersion = '1.0';
      String userAgent = 'Flutter SDK';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        osName = 'Android';
        osVersion = androidInfo.version.release;
        deviceType = 'mobile';
        isMobile = true;
        mobileVendor = androidInfo.manufacturer;
        mobileModel = androidInfo.model;
        userAgent = 'Android ${androidInfo.version.release} / ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        osName = 'iOS';
        osVersion = iosInfo.systemVersion;
        deviceType = iosInfo.model.toLowerCase().contains('ipad') ? 'tablet' : 'mobile';
        isMobile = deviceType == 'mobile';
        isTablet = deviceType == 'tablet';
        mobileVendor = 'Apple';
        mobileModel = iosInfo.model;
        userAgent = 'iOS ${iosInfo.systemVersion} / ${iosInfo.model}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        osName = 'macOS';
        osVersion = macInfo.osRelease;
        deviceType = 'desktop';
        isDesktop = true;
        userAgent = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        osName = 'Windows';
        osVersion = windowsInfo.majorVersion.toString();
        deviceType = 'desktop';
        isDesktop = true;
        userAgent = 'Windows ${windowsInfo.majorVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        osName = 'Linux';
        osVersion = linuxInfo.version ?? 'Unknown';
        deviceType = 'desktop';
        isDesktop = true;
        userAgent = 'Linux ${linuxInfo.version ?? "Unknown"}';
      }

      return DeviceInfo(
        browserName: browserName,
        browserVersion: browserVersion,
        deviceType: deviceType,
        osName: osName,
        osVersion: osVersion,
        isMobile: isMobile,
        isTablet: isTablet,
        isDesktop: isDesktop,
        mobileVendor: mobileVendor,
        mobileModel: mobileModel,
        userAgent: userAgent,
        screenWidth: screenWidth.toInt(),
        screenHeight: screenHeight.toInt(),
        viewportWidth: viewportWidth.toInt(),
        viewportHeight: viewportHeight.toInt(),
        devicePixelRatio: devicePixelRatio,
      );
    } catch (e) {
      print('Error collecting device info: $e');
      return null;
    }
  }

  /// Get device locale language code
  static String getDeviceLanguageCode() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return locale.languageCode;
    } catch (e) {
      return 'en'; // Default to English
    }
  }
}
