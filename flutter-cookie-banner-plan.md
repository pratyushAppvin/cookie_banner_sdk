# Flutter Cookie Banner SDK - Implementation Plan

## Goal

Port the existing React/TypeScript cookie banner into a reusable Flutter SDK, preserving full functionality (GDPR/CCPA compliance, dynamic configuration, consent storage, integrations) while exposing a simple, prop-like configuration API to host apps.

---

## High-Level Architecture

- **Package Type**: Flutter module / SDK (not a standalone app).
- **Entry Point**: A single public widget `CookieBanner` exposed from `lib/`.
- **Dynamic Configuration**: All runtime configuration (domain URL, environment base URL, domain ID, theming, layout) is passed in through widget parameters, similar to React props.
- **Layers**:
  - **Presentation layer**: Flutter widgets for wall banner, footer banner, floating logo, loaders.
  - **Domain layer**: Dart models mirroring the TypeScript interfaces.
  - **Data layer**: HTTP client, consent persistence (shared_preferences), and cookie data mapping.
  - **Integration layer (later)**: hooks for GTM/Adobe/JS shim where possible, or documented as host responsibilities.

---

## Data Models (Dart)

Mirror the existing TypeScript interfaces in `cookie-banner.tsx` as Dart classes:

- `CookieConsent`
- `DeviceInfoData` and `DeviceInfo`
- `CookieProperties`
- `ServiceProperties`
- `CategoryConsentRecordProperties`
- `UserDataProperties`
- `BannerDesign`
- `BannerConfigurations`
- `Language`

These will live under `lib/src/models/` and be JSON-serializable using factory constructors.

---

## Public Widget API

`CookieBanner` will be the main entry point, similar to the React component props:

```dart
class CookieBanner extends StatefulWidget {
  final String domainUrl;          // Equivalent to React domainUrl prop
  final String environment;        // Base URL for backend APIs
  final int? domainId;             // Optional domain identifier

  // Optional overrides for theming and layout if host wants to bypass remote config
  final BannerDesign? overrideDesign;

  const CookieBanner({
    super.key,
    required this.domainUrl,
    required this.environment,
    this.domainId,
    this.overrideDesign,
  });

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}
```

All dynamic aspects (domain, environment, layout overrides) come from the host application, preserving the SDK’s dynamic nature.

---

## Feature Parity Plan

### 1. Consent Categories & Actions

- Categories: necessary, analytics, marketing, functional, performance.
- Actions: **Accept All**, **Reject All**, **Allow Selection**.
- Implement local state in `_CookieBannerState`:
  - `Map<int, bool> categoryConsent`
  - `Map<int, bool> userConsentPerCookie`
- Recreate the helpers:
  - `getConsentBySlug`
  - `buildEffectiveConsent` (including Do Not Track handling)
  - `persistConsentCookie` (adapted to Flutter’s storage model)

### 2. Layouts: Wall & Footer

- **Wall layout**: full-screen modal using `Dialog` / `showGeneralDialog` or `Stack` overlay.
- **Footer layout**: bottom-aligned banner using `Align` or `Positioned` inside a `Stack`.
- **Floating logo**: small draggable widget that re-opens preferences.
- Use configuration from `BannerDesign` to choose layout type (`wall` | `footer`).

### 3. Language & Translations

- Fetch available languages via HTTP as per documentation.
- Keep state:
  - `String selectedLanguage`
  - `List<Language> languages`
  - `UserDataProperties? translatedData`
- Implement:
  - Automatic detection via `ui.window.locale.languageCode`.
  - Manual selection via a `DropdownButton`.
  - Re-fetch / switch banner text on language changes without reloading the widget tree.

### 4. HTTP & Remote Configuration

- Use `http` package to call the documented endpoints:
  - CDN JSON for banner config.
  - Backend endpoints for fallback, consent updates, load-time metrics, languages.
- Mirror the React flow:
  1. Try CDN banner JSON.
  2. Fallback to API if CDN unavailable.
  3. Store `apiCookieUserData` vs `localCookieUserData` to distinguish remote vs local modifications.

### 5. Consent Persistence & New Cookie Detection

- Use `shared_preferences` to persist:
  - Consent choices per category & per cookie (`total_cookies`, `total_categories`).
  - Subject identity (UUID).
  - Last seen cookie set / consent version.
- Implement logic equivalent to `persistConsentCookie` and `checkForNewCookies`:
  - Compare remote cookie list to stored `available_cookies`.
  - If new cookies or bumped `consent_version` → show banner again.

### 6. Do Not Track Support

- Read DNT equivalent:
  - On web: via `dart:html` (only for Flutter web builds).
  - On mobile/desktop: expose a `bool respectDnt` flag or document that DNT is only available on web.
- Apply same rule: if DNT is enabled, marketing is always denied.

### 7. Device & Browser Info Collection

- Use plugins:
  - `device_info_plus` (to be added if required) for device/OS data.
  - `universal_io` or `dart:html` on web for user agent and screen size.
- Map collected data into `DeviceInfo` and send with each consent action.

### 8. Third-Party/JS Integrations

For this first Dart/Flutter SDK iteration:

- Expose callbacks instead of direct GTM/Adobe integration:
  - `ValueChanged<Map<int, bool>>? onConsentChanged;`
  - `VoidCallback? onAcceptAll;`
  - `VoidCallback? onRejectAll;`
- For Flutter web, optionally bridge to JS via `package:js` or `dart:js` if the host wants to call GoTrust shim or GTM; document these as integration points rather than hard dependencies.

---

## UI Implementation Notes

- Use only Flutter core widgets and simple packages already in pubspec.
- Mirror visual behavior described in the React documentation:
  - Responsive styles via `LayoutBuilder` and media query breakpoints.
  - Button ordering and visibility driven by `BannerDesign.buttons` and `buttonOrder`.
  - Skeleton/loader widgets while config is loading.
- Keep all styling inside the widget tree (no platform-specific UI code required).

---

## Pubspec Changes

Update this SDK’s `pubspec.yaml` to include the dependencies required for network calls, storage, and UI behavior, following the provided example pubspec:

- Add runtime dependencies:
  - `http`
  - `shared_preferences`
  - `url_launcher` (for privacy/cookie policy links)
  - `flutter_markdown` or `flutter_widget_from_html_core` (to render rich banner descriptions)
  - `intl` (for dates / localization if needed)
  - `file_picker` and `country_code_picker` only if used in the consent UI (can be deferred if not strictly required).
- Add assets section if we bundle any local icons or images.
- Keep the package as a **module/SDK**, not an app (no main UI entry beyond the widget).

Concrete pubspec changes will be made directly in `pubspec.yaml` in this repo using the attached YAML as a reference.

---

## Dynamic Configuration Strategy

To preserve the SDK’s dynamic nature:

- **Never hard-code domain or environment**: always accept via `CookieBanner` constructor.
- **Remote-driven UI**: by default, load `BannerDesign` from backend/CDN instead of baking it into the SDK.
- **Override-friendly design**: allow host apps to override certain design elements via optional parameters without forking the core logic.
- **Minimal opinionated state**: store only what’s required for consent logic; all other display decisions come from server-side configuration.

---

## Implementation Phases

1. **Scaffold SDK structure**
   - Create `lib/src/models`, `lib/src/services`, `lib/src/widgets`.
   - Add data models and HTTP client service.

2. **Basic banner rendering**
   - Implement `CookieBanner` widget.
   - Implement footer banner layout and basic actions (accept/reject all).

3. **Full consent logic & persistence**
   - Implement category/cookie-level toggles, DNT, storage, and new cookie detection.

4. **Multi-language and translations**
   - Add language list fetching and translated data switching.

5. **Wall layout, floating logo, loaders**
   - Complete UI parity with React component.

6. **Integration hooks & polish**
   - Add callbacks, JS bridging hooks (for web), error handling, and docs.

---

## Next Steps in This Repo

- Update `pubspec.yaml` to add the required packages.
- Implement the model classes and the core `CookieBanner` widget under `lib/`.
- Incrementally port logic from the React implementation, validating behavior against the existing documentation.
