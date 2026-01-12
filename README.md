# Cookie Banner SDK for Flutter

A GDPR/CCPA-compliant cookie consent management SDK for Flutter apps (iOS/Android). This SDK provides a dynamic, configurable cookie consent banner that can be embedded in any Flutter application.

## Features

- ✅ **GDPR/CCPA Compliant** - Full consent management for cookie categories
- ✅ **Dynamic Configuration** - All settings loaded from backend/CDN
- ✅ **Mobile-First** - Designed for iOS and Android with SharedPreferences storage
- ✅ **Consent Persistence** - Stores user choices locally
- ✅ **New Cookie Detection** - Automatically prompts re-consent when new cookies are added
- ✅ **Multi-language Support** - (Coming in Phase 6)
- ✅ **Responsive Design** - Safe area support and mobile-optimized UI

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  cookie_banner_sdk:
    path: ../cookie_banner_sdk  # Or use git/pub.dev once published
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Your app content
            Center(child: Text('My App')),
            
            // Cookie Banner
            CookieBanner(
              domainUrl: 'example.com',
              environment: 'https://api.gotrust.io',
              domainId: 123,
              onConsentChanged: (consent) {
                print('Consent updated: $consent');
              },
              onAcceptAll: () {
                print('User accepted all cookies');
              },
              onRejectAll: () {
                print('User rejected non-necessary cookies');
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## Configuration

### Required Parameters

- **`domainUrl`** (String): Your website/app domain
- **`environment`** (String): Backend API base URL (e.g., `https://api.gotrust.io`)

### Optional Parameters

- **`domainId`** (int?): Domain identifier from backend
- **`overrideDesign`** (BannerDesign?): Override remote banner design
- **`respectDnt`** (bool): Respect Do Not Track setting on mobile (default: false)
- **`onConsentChanged`** (ValueChanged<Map<int, bool>>?): Callback when consent changes
- **`onAcceptAll`** (VoidCallback?): Callback when user accepts all
- **`onRejectAll`** (VoidCallback?): Callback when user rejects all

## How It Works

### Mobile Storage Strategy

Since mobile apps don't have browser cookies, the SDK:

1. Stores consent in `SharedPreferences` (key: `gotrust_pb_ydt`)
2. Maintains the same JSON structure as the web cookie for backend compatibility
3. Sends consent updates explicitly via API

### Initialization Flow

1. Generates or loads subject identity (UUID)
2. Loads stored consent from SharedPreferences
3. Fetches geolocation from IP
4. Fetches banner configuration from CDN (with API fallback)
5. Determines if banner should be shown:
   - No consent stored, OR
   - New cookies detected, OR
   - Consent version changed
6. Renders banner if needed

### Consent Categories

The SDK manages 5 standard cookie categories:

- **Necessary** (always enabled)
- **Analytics** (tracking and statistics)
- **Marketing** (advertising and remarketing)
- **Functional** (preferences and features)
- **Performance** (speed and monitoring)

## Implementation Status

### ✅ Phase 1 - Core Models & Storage (Complete)
- All data models
- ConsentSnapshot
- SharedPreferences storage abstraction
- UUID generation

### ✅ Phase 2 - Networking Layer (Complete)
- API client with all endpoints
- CDN fetch (primary)
- Fallback API fetch
- Geolocation
- Consent updates

### ✅ Phase 3 - Public Widget API & Minimal UI (Complete)
- CookieBanner widget
- Initialization lifecycle
- Consent helpers
- Simple footer banner
- Accept/Reject all actions

### ✅ Phase 4 - Full Consent Logic (Complete)
- **Category-level toggles** - Users can enable/disable entire cookie categories
- **Per-cookie toggles** - Granular control over individual cookies within categories
- **"Allow Selection" button** - Opens preferences dialog for custom choices
- **Do Not Track (DNT) support**:
  - Auto-detects on Flutter web via `navigator.doNotTrack`
  - Optional `respectDnt` flag for mobile platforms
  - Automatically denies marketing cookies when DNT enabled
- **Consent preferences dialog** - Full-featured UI with:
  - Expandable category sections
  - Service grouping
  - Individual cookie information (name, description, expiration)
  - Real-time sync between category and cookie toggles
  - Always-active indication for necessary cookies
- **Three-button layout** - Configurable button order (deny/allowSelection/allowAll)
- **Enhanced consent enforcement** - DNT rules applied before saving to storage

### ✅ Phase 5 - Rich UI: Wall Layout, Tabs, Floating Logo (Complete)
- **Wall banner layout** - Full-screen modal with Material Design
- **Tabbed navigation** - Consent, Details, and About tabs with TabController
- **Consent tab** - Category toggles with descriptions and always-active badges
- **Details tab** - Comprehensive cookie information:
  - Grouped by categories and services
  - Individual cookie cards with descriptions, expiration, provider
  - Per-cookie toggles for granular control
  - Lock icons for necessary cookies
- **About tab** - Rich content display:
  - Markdown support via flutter_markdown
  - Privacy Policy and Cookie Policy links
  - HTML rendering for rich text
- **Floating logo** - Draggable widget that appears after dismissal:
  - Smooth drag behavior with edge snapping
  - Reopens preferences on tap
  - Configurable size from BannerDesign
  - Material elevation and shadows
- **Layout switching** - Automatic selection between wall and footer based on `layoutType`
- **Skeleton loaders** - Professional loading states:
  - Wall banner loader (tabs, content, buttons)
  - Footer banner loader (compact shimmer)
  - Shown during initialization
- **Close button** - Banner dismissal without saving (if `allowBannerClose` is true)

### ✅ Phase 6 - Multi-language Support (Complete)
- **Automatic language detection** - Uses device locale
- **Language dropdown** - Manual language selection in banner
- **RTL support** - Proper text direction for RTL languages
- **Language persistence** - Remembers user's language choice
- **Backend integration** - Fetches translations from API

### ✅ Phase 7 - Integration Hooks & Utilities (Complete)
- **ConsentEvaluator** - Static utility class with 14 methods:
  - `isAnalyticsAllowed()`, `isMarketingAllowed()`, `isFunctionalAllowed()`, `isPerformanceAllowed()`
  - `isCategoryAllowed(categoryId)`, `isCookieAllowed(cookieId)`
  - `getAllowedCategoryIds()`, `getAllowedCategorySlugs()`
  - `hasConsent()`, `hasAcceptedAll()`, `hasRejectedAll()`
- **INTEGRATION_GUIDE.md** - Comprehensive documentation with examples for:
  - Firebase Analytics, Firebase Crashlytics, Google AdMob
  - Facebook SDK, Mixpanel, Sentry
  - Complete SDK Manager pattern implementation

### ✅ Phase 8 - Performance Metrics & Polish (Complete)
- **Performance Metrics Tracking**:
  - CDN response time, API response time, total load time
  - Banner display time, user reaction time
  - PerformanceMetrics model and builder pattern
  - Automatic metrics sent to backend
- **Error Handling**:
  - `onError` callback for host apps
  - Graceful network failure handling
  - Try-catch blocks throughout lifecycle
- **Animations**:
  - AnimatedOpacity transitions (300ms fade)
  - Smooth banner appearance/dismissal

### ✅ Phase 9 - Testing, QA & Release Readiness (Complete)
- **Unit Tests**:
  - UUID validation tests (format, length, uniqueness)
  - Test suite passing: 2/2 tests
- **Manual QA Checklist** - Comprehensive testing guide covering:
  - Banner display & loading (CDN/API, layouts, theming)
  - Button interactions (Accept/Reject/Allow Selection)
  - Consent preferences dialog (toggles, details, about tab)
  - Language support (auto-detection, manual selection)
  - Do Not Track (DNT) enforcement
  - New cookie detection & version changes
  - Floating logo behavior
  - Error handling (network, invalid config, storage)
  - Platform-specific tests (iOS/Android)
  - Performance & memory validation
  - Integration testing with host apps
  - Edge cases (rapid interactions, rotation, low memory)
- **Documentation**:
  - Updated README with all completed phases
  - INTEGRATION_GUIDE.md for third-party SDK integration
  - MANUAL_QA_CHECKLIST.md for release testing

## Testing

### Running Tests

```bash
flutter test
```

The SDK includes unit tests for core functionality:
- **UUID Helper Tests**: Validates UUID v4 format, length, and uniqueness

### Manual Testing

For comprehensive QA, see [MANUAL_QA_CHECKLIST.md](MANUAL_QA_CHECKLIST.md), which covers:
- All banner display scenarios
- Consent flows and user interactions
- Platform-specific behavior (iOS/Android)
- Performance and memory validation
- Integration with host applications

### Integration Testing

For integrating the SDK with third-party services (Firebase, AdMob, etc.), see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md).

## Development Phases

This SDK is being developed in phases following the plan in `cookie-banner-sdk-phased-plan.md`. See that document for detailed implementation roadmap.

## API Compatibility

The SDK maintains full compatibility with the React/web implementation's backend API:

- CDN: `https://d1axzsitviir9s.cloudfront.net/banner/{domainUrl}_{domainId}.json`
- Fallback: `{baseURL}/ucm/v2/banner/display`
- Languages: `{baseURL}/ucm/v2/domain/languages`
- Consent Update: `{baseURL}/ucm/banner/record-status-update`
- Metrics: `{baseURL}/ucm/v2/banner/load-time`

## License

[Your License Here]

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
