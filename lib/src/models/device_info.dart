/// Device information for analytics, mirroring TypeScript `DeviceInfo` interface.
class DeviceInfo {
  final String browserName;
  final String browserVersion;
  final String deviceType;
  final String osName;
  final String osVersion;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final String? mobileVendor;
  final String? mobileModel;
  final String userAgent;
  final int screenWidth;
  final int screenHeight;
  final int viewportWidth;
  final int viewportHeight;
  final double devicePixelRatio;

  const DeviceInfo({
    required this.browserName,
    required this.browserVersion,
    required this.deviceType,
    required this.osName,
    required this.osVersion,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    this.mobileVendor,
    this.mobileModel,
    required this.userAgent,
    required this.screenWidth,
    required this.screenHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.devicePixelRatio,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      browserName: json['browserName'] as String? ?? '',
      browserVersion: json['browserVersion'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      osName: json['osName'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
      isMobile: json['isMobile'] as bool? ?? false,
      isTablet: json['isTablet'] as bool? ?? false,
      isDesktop: json['isDesktop'] as bool? ?? false,
      mobileVendor: json['mobileVendor'] as String?,
      mobileModel: json['mobileModel'] as String?,
      userAgent: json['userAgent'] as String? ?? '',
      screenWidth: json['screenWidth'] as int? ?? 0,
      screenHeight: json['screenHeight'] as int? ?? 0,
      viewportWidth: json['viewportWidth'] as int? ?? 0,
      viewportHeight: json['viewportHeight'] as int? ?? 0,
      devicePixelRatio: (json['devicePixelRatio'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'browserName': browserName,
      'browserVersion': browserVersion,
      'deviceType': deviceType,
      'osName': osName,
      'osVersion': osVersion,
      'isMobile': isMobile,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
      if (mobileVendor != null) 'mobileVendor': mobileVendor,
      if (mobileModel != null) 'mobileModel': mobileModel,
      'userAgent': userAgent,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'viewportWidth': viewportWidth,
      'viewportHeight': viewportHeight,
      'devicePixelRatio': devicePixelRatio,
    };
  }
}

/// Device information sent to backend API, mirrors TypeScript `DeviceInfoData`.
class DeviceInfoData {
  final BrowserInfo browser;
  final OperatingSystemInfo operatingSystem;
  final DeviceDetails device;
  final ScreenInfo screen;

  const DeviceInfoData({
    required this.browser,
    required this.operatingSystem,
    required this.device,
    required this.screen,
  });

  factory DeviceInfoData.fromJson(Map<String, dynamic> json) {
    return DeviceInfoData(
      browser: BrowserInfo.fromJson(json['browser'] as Map<String, dynamic>),
      operatingSystem: OperatingSystemInfo.fromJson(
          json['operating_system'] as Map<String, dynamic>),
      device: DeviceDetails.fromJson(json['device'] as Map<String, dynamic>),
      screen: ScreenInfo.fromJson(json['screen'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'browser': browser.toJson(),
      'operating_system': operatingSystem.toJson(),
      'device': device.toJson(),
      'screen': screen.toJson(),
    };
  }

  /// Convert from simplified DeviceInfo to structured DeviceInfoData
  factory DeviceInfoData.fromDeviceInfo(DeviceInfo info) {
    return DeviceInfoData(
      browser: BrowserInfo(
        name: info.browserName,
        version: info.browserVersion,
        userAgent: info.userAgent,
      ),
      operatingSystem: OperatingSystemInfo(
        name: info.osName,
        version: info.osVersion,
      ),
      device: DeviceDetails(
        type: info.deviceType,
        isMobile: info.isMobile,
        isTablet: info.isTablet,
        isDesktop: info.isDesktop,
        vendor: info.mobileVendor,
        model: info.mobileModel,
      ),
      screen: ScreenInfo(
        width: info.screenWidth,
        height: info.screenHeight,
        viewportWidth: info.viewportWidth,
        viewportHeight: info.viewportHeight,
        devicePixelRatio: info.devicePixelRatio,
      ),
    );
  }
}

class BrowserInfo {
  final String name;
  final String version;
  final String userAgent;

  const BrowserInfo({
    required this.name,
    required this.version,
    required this.userAgent,
  });

  factory BrowserInfo.fromJson(Map<String, dynamic> json) {
    return BrowserInfo(
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'user_agent': userAgent,
    };
  }
}

class OperatingSystemInfo {
  final String name;
  final String version;

  const OperatingSystemInfo({
    required this.name,
    required this.version,
  });

  factory OperatingSystemInfo.fromJson(Map<String, dynamic> json) {
    return OperatingSystemInfo(
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
    };
  }
}

class DeviceDetails {
  final String type;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final String? vendor;
  final String? model;

  const DeviceDetails({
    required this.type,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    this.vendor,
    this.model,
  });

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    return DeviceDetails(
      type: json['type'] as String? ?? '',
      isMobile: json['is_mobile'] as bool? ?? false,
      isTablet: json['is_tablet'] as bool? ?? false,
      isDesktop: json['is_desktop'] as bool? ?? false,
      vendor: json['vendor'] as String?,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'is_mobile': isMobile,
      'is_tablet': isTablet,
      'is_desktop': isDesktop,
      if (vendor != null) 'vendor': vendor,
      if (model != null) 'model': model,
    };
  }
}

class ScreenInfo {
  final int width;
  final int height;
  final int viewportWidth;
  final int viewportHeight;
  final double devicePixelRatio;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.devicePixelRatio,
  });

  factory ScreenInfo.fromJson(Map<String, dynamic> json) {
    return ScreenInfo(
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      viewportWidth: json['viewport_width'] as int? ?? 0,
      viewportHeight: json['viewport_height'] as int? ?? 0,
      devicePixelRatio:
          (json['device_pixel_ratio'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'viewport_width': viewportWidth,
      'viewport_height': viewportHeight,
      'device_pixel_ratio': devicePixelRatio,
    };
  }
}
