# Host App Integration Guide

This guide explains how to integrate the Cookie Banner SDK into your Flutter app and enforce consent choices on third-party SDKs.

## Table of Contents

1. [Basic Setup](#basic-setup)
2. [Listening to Consent Changes](#listening-to-consent-changes)
3. [Reading Stored Consent](#reading-stored-consent)
4. [Integration with Popular SDKs](#integration-with-popular-sdks)
5. [Advanced Usage](#advanced-usage)

---

## Basic Setup

Add the cookie banner widget to your app:

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          // Your app content
          MyHomePage(),
          
          // Cookie banner overlay
          CookieBanner(
            domainId: 12345,
            domainUrl: 'https://example.com',
            environment: 'https://api.example.com',
            onConsentChanged: (categoryConsent) {
              // Handle consent changes
              print('Consent updated: $categoryConsent');
            },
            onAcceptAll: () {
              print('User accepted all cookies');
            },
            onRejectAll: () {
              print('User rejected all cookies');
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Listening to Consent Changes

Use the callbacks to react immediately when users make consent choices:

```dart
CookieBanner(
  domainId: 12345,
  domainUrl: 'https://example.com',
  environment: 'https://api.example.com',
  onConsentChanged: (Map<int, bool> categoryConsent) {
    // categoryConsent contains: {categoryId: isAllowed}
    
    // Example: Enable/disable analytics based on consent
    for (final entry in categoryConsent.entries) {
      final categoryId = entry.key;
      final isAllowed = entry.value;
      
      if (categoryId == 2) { // Assuming 2 is analytics
        if (isAllowed) {
          _enableAnalytics();
        } else {
          _disableAnalytics();
        }
      }
    }
  },
  onAcceptAll: () {
    // User clicked "Accept All"
    _enableAllTracking();
  },
  onRejectAll: () {
    // User clicked "Reject All"
    _disableNonEssentialTracking();
  },
);
```

---

## Reading Stored Consent

On app startup, read the stored consent to initialize SDKs:

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  @override
  void initState() {
    super.initState();
    _initializeSDKsBasedOnConsent();
  }

  Future<void> _initializeSDKsBasedOnConsent() async {
    // Load stored consent
    final snapshot = await _storage.loadConsent();
    
    // Use ConsentEvaluator to check specific categories
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
      await _initializeFirebaseAnalytics();
    }
    
    if (ConsentEvaluator.isMarketingAllowed(snapshot)) {
      await _initializeFacebookSDK();
      await _initializeAdMob();
    }
    
    if (ConsentEvaluator.isPerformanceAllowed(snapshot)) {
      await _initializeCrashlytics();
    }
  }

  Future<void> _initializeFirebaseAnalytics() async {
    // Initialize your analytics SDK
    print('Initializing Firebase Analytics');
  }

  Future<void> _initializeFacebookSDK() async {
    // Initialize Facebook SDK
    print('Initializing Facebook SDK');
  }

  Future<void> _initializeAdMob() async {
    // Initialize AdMob
    print('Initializing AdMob');
  }

  Future<void> _initializeCrashlytics() async {
    // Initialize Crashlytics
    print('Initializing Crashlytics');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          MyHomePage(),
          CookieBanner(
            domainId: 12345,
            domainUrl: 'https://example.com',
            environment: 'https://api.example.com',
            onConsentChanged: (consent) => _handleConsentChange(consent),
          ),
        ],
      ),
    );
  }

  void _handleConsentChange(Map<int, bool> categoryConsent) async {
    // Save and re-initialize SDKs based on new consent
    await _initializeSDKsBasedOnConsent();
  }
}
```

---

## Integration with Popular SDKs

### Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      print('Firebase Analytics enabled');
    } else {
      await _analytics.setAnalyticsCollectionEnabled(false);
      print('Firebase Analytics disabled');
    }
  }

  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    final snapshot = await _storage.loadConsent();
    
    // Only log if analytics consent is given
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    }
  }
}
```

### Facebook SDK

```dart
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class FacebookService {
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isMarketingAllowed(snapshot)) {
      // Initialize Facebook SDK
      await FacebookAuth.instance.autoLogAppEventsEnabled(true);
      print('Facebook SDK enabled');
    } else {
      await FacebookAuth.instance.autoLogAppEventsEnabled(false);
      print('Facebook SDK disabled');
    }
  }
}
```

### Google AdMob

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class AdMobService {
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isMarketingAllowed(snapshot)) {
      await MobileAds.instance.initialize();
      print('AdMob initialized');
    } else {
      print('AdMob disabled due to lack of marketing consent');
    }
  }

  Future<BannerAd?> loadBannerAd() async {
    final snapshot = await _storage.loadConsent();
    
    // Only show ads if marketing consent is given
    if (!ConsentEvaluator.isMarketingAllowed(snapshot)) {
      return null;
    }

    final BannerAd bannerAd = BannerAd(
      adUnitId: 'your-ad-unit-id',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(),
    );

    await bannerAd.load();
    return bannerAd;
  }
}
```

### Mixpanel

```dart
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class MixpanelService {
  Mixpanel? _mixpanel;
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
      _mixpanel = await Mixpanel.init(
        'your-mixpanel-token',
        trackAutomaticEvents: true,
      );
      print('Mixpanel initialized');
    } else {
      _mixpanel = null;
      print('Mixpanel disabled');
    }
  }

  Future<void> track(String eventName, {Map<String, dynamic>? properties}) async {
    final snapshot = await _storage.loadConsent();
    
    // Only track if analytics consent is given
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot) && _mixpanel != null) {
      _mixpanel!.track(eventName, properties: properties);
    }
  }
}
```

### Firebase Crashlytics

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class CrashlyticsService {
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isPerformanceAllowed(snapshot)) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      print('Crashlytics enabled');
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      print('Crashlytics disabled');
    }
  }
}
```

### Sentry

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class SentryService {
  final ConsentStorage _storage = SharedPreferencesConsentStorage();

  Future<void> initializeBasedOnConsent() async {
    final snapshot = await _storage.loadConsent();
    
    if (ConsentEvaluator.isPerformanceAllowed(snapshot)) {
      await SentryFlutter.init(
        (options) {
          options.dsn = 'your-sentry-dsn';
          options.tracesSampleRate = 1.0;
        },
      );
      print('Sentry initialized');
    } else {
      print('Sentry disabled');
    }
  }
}
```

---

## Advanced Usage

### Complete SDK Manager

Here's a complete example of an SDK manager that handles all third-party services:

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SDKManager {
  static final SDKManager _instance = SDKManager._internal();
  factory SDKManager() => _instance;
  SDKManager._internal();

  final ConsentStorage _storage = SharedPreferencesConsentStorage();
  bool _initialized = false;

  /// Initialize all SDKs based on stored consent
  Future<void> initializeAll() async {
    if (_initialized) return;

    final snapshot = await _storage.loadConsent();

    // Analytics SDKs
    if (ConsentEvaluator.isAnalyticsAllowed(snapshot)) {
      await _initializeAnalytics();
    }

    // Marketing SDKs
    if (ConsentEvaluator.isMarketingAllowed(snapshot)) {
      await _initializeMarketing();
    }

    // Performance SDKs
    if (ConsentEvaluator.isPerformanceAllowed(snapshot)) {
      await _initializePerformance();
    }

    // Functional SDKs - typically always enabled if necessary
    if (ConsentEvaluator.isFunctionalAllowed(snapshot)) {
      await _initializeFunctional();
    }

    _initialized = true;
  }

  /// Re-initialize SDKs when consent changes
  Future<void> handleConsentChange(Map<int, bool> categoryConsent) async {
    _initialized = false;
    await initializeAll();
  }

  Future<void> _initializeAnalytics() async {
    print('Initializing analytics SDKs...');
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    // Add more analytics SDKs here
  }

  Future<void> _initializeMarketing() async {
    print('Initializing marketing SDKs...');
    await MobileAds.instance.initialize();
    // Add more marketing SDKs here
  }

  Future<void> _initializePerformance() async {
    print('Initializing performance SDKs...');
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    // Add more performance SDKs here
  }

  Future<void> _initializeFunctional() async {
    print('Initializing functional SDKs...');
    // Add functional SDKs here
  }
}

// Usage in main.dart:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SDKs based on existing consent
  await SDKManager().initializeAll();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          MyHomePage(),
          CookieBanner(
            domainId: 12345,
            domainUrl: 'https://example.com',
            environment: 'https://api.example.com',
            onConsentChanged: (consent) async {
              // Re-initialize SDKs when consent changes
              await SDKManager().handleConsentChange(consent);
            },
          ),
        ],
      ),
    );
  }
}
```

### Checking Specific Cookie Consent

For fine-grained control, check individual cookie consent:

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

Future<void> checkSpecificCookie() async {
  final storage = SharedPreferencesConsentStorage();
  final snapshot = await storage.loadConsent();
  
  // Check if a specific cookie (by ID) is allowed
  final googleAnalyticsCookieId = 123; // Example cookie ID
  if (ConsentEvaluator.isCookieAllowed(snapshot, googleAnalyticsCookieId)) {
    print('Google Analytics cookie is allowed');
  }
}
```

### Getting All Allowed Categories

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

Future<void> getAllowedCategories() async {
  final storage = SharedPreferencesConsentStorage();
  final snapshot = await storage.loadConsent();
  
  // Get list of allowed category IDs
  final allowedIds = ConsentEvaluator.getAllowedCategoryIds(snapshot);
  print('Allowed category IDs: $allowedIds');
  
  // With user data, get category slugs
  // final allowedSlugs = ConsentEvaluator.getAllowedCategorySlugs(snapshot, userData);
  // print('Allowed categories: $allowedSlugs');
}
```

### Checking Consent Status

```dart
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

Future<void> checkConsentStatus() async {
  final storage = SharedPreferencesConsentStorage();
  final snapshot = await storage.loadConsent();
  
  // Check if any consent has been given
  if (ConsentEvaluator.hasConsent(snapshot)) {
    print('User has made consent choices');
    
    // Check if user accepted all
    if (ConsentEvaluator.hasAcceptedAll(snapshot)) {
      print('User accepted all cookies');
    }
    
    // Check if user rejected all (with userData)
    // if (ConsentEvaluator.hasRejectedAll(snapshot, userData)) {
    //   print('User rejected all non-essential cookies');
    // }
  } else {
    print('No consent given yet - banner should be shown');
  }
}
```

---

## Best Practices

1. **Initialize on App Start**: Always check stored consent on app startup before initializing any tracking SDKs.

2. **Respect User Choices**: Disable SDKs immediately when consent is revoked.

3. **Handle No Consent**: If no consent exists yet, assume the most privacy-friendly default (disable all non-essential tracking).

4. **Test Thoroughly**: Test your app with different consent scenarios:
   - No consent given
   - Accept all
   - Reject all
   - Partial consent

5. **Handle Errors Gracefully**: Wrap SDK initialization in try-catch blocks to prevent app crashes.

6. **Update Documentation**: Keep your privacy policy updated to reflect which SDKs you use for each category.

---

## Support

For issues or questions, please refer to the main SDK documentation or contact support.
