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

### 🚧 Phase 4 - Full Consent Logic (Next)
- Category-level toggles
- Per-cookie toggles
- Do Not Track support
- New cookie detection refinements

### 📋 Phase 5+ - Upcoming
- Wall layout (full-screen modal)
- Multi-language support
- Device info collection
- Floating logo
- Performance metrics

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
