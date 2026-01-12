# Cookie Banner Flutter SDK – Phase-wise Integration Plan (Mobile-first)

## 0. Objectives & Constraints

- **Goal**: Reproduce the existing React cookie banner functionality as a **Flutter SDK** that can be embedded in iOS/Android apps.
- **Platforms**: Android, iOS (Flutter mobile first). Flutter web support is a bonus, not the primary target.
- **Dynamic by Design**: All configuration (domain URL, environment, domain ID, theming) is passed in from the host app, just like React props.
- **Key Difference vs Web**:
  - Browsers store cookies in a shared cookie jar; native apps do **not**.
  - We will **simulate** the consent cookie (`gotrust_pb_ydt`) via local storage (e.g. `shared_preferences`) and send consent to the backend explicitly via APIs.
  - If this SDK is used on Flutter web, we additionally set a real browser cookie for parity using `dart:html`.

---

## Phase 1 – Core Domain Model & Storage Abstraction

**Deliverables**
- Dart model classes under `lib/src/models/` mirroring the TypeScript interfaces:
  - `CookieConsent`, `CookieProperties`, `ServiceProperties`,
    `CategoryConsentRecordProperties`, `UserDataProperties`,
    `BannerDesign`, `BannerConfigurations`, `Language`, `DeviceInfo`, `DeviceInfoData`.
- A **consent snapshot** model representing what we would normally store in `gotrust_pb_ydt`.
- Storage abstraction for mobile-friendly consent persistence.

**Implementation Notes**
- Create:
  - `ConsentSnapshot` (maps 1:1 to the JSON structure of `gotrust_pb_ydt`).
  - `ConsentStorage` interface with methods like:
    - `Future<ConsentSnapshot?> loadConsent();`
    - `Future<void> saveConsent(ConsentSnapshot snapshot);`
    - `Future<void> clearConsent();`
  - Default implementation `SharedPreferencesConsentStorage` using `shared_preferences` to store a single JSON string under key `gotrust_pb_ydt`.
- For future Flutter web support, create a separate implementation `BrowserCookieConsentStorage` (using `dart:html` to read/write the real cookie); wiring will be done in a later phase.

**Mobile Cookie Handling Strategy**
- On **mobile**, there is no cookie jar; we treat `SharedPreferences` as the canonical store for consent data.
- The stored JSON should remain compatible with the web cookie format to keep backend behavior and versioning consistent.

---

## Phase 2 – Networking Layer & Configuration Fetch

**Deliverables**
- HTTP client service under `lib/src/services/` using the existing `http` package.
- Functions to fetch:
  - CDN banner config JSON.
  - Fallback API banner config.
  - Available languages.
  - Consent update endpoint.
  - Performance/load-time metrics endpoint.

**Implementation Notes**
- Create a `CookieBannerApiClient` with methods like:
  - `Future<List<UserDataProperties>> fetchBannerDataFromCdn(String domainUrl, int domainId);`
  - `Future<UserDataProperties> fetchBannerDataFallback({required int domainId, required String subjectIdentity, required String countryName});`
  - `Future<List<Language>> fetchLanguages(int domainId);`
  - `Future<void> updateConsent(ConsentSnapshot snapshot, DeviceInfo? deviceInfo);`
  - `Future<void> sendLoadTimeMetrics(...);`
- The `environment` string passed into the widget acts as `baseURL`.
- Map the JSON contracts exactly as described in the React documentation to keep backend compatibility.

**Mobile Considerations**
- Use the `environment` prop to choose between dev/staging/prod.
- All requests are done via mobile networking; no reliance on browser cookies or auto-sent cookie headers.
- If backend expects `gotrust_pb_ydt` as a cookie, we instead:
  - Include the **equivalent information in the request body** (as done in the React code), which already contains `subject_identity`, `domain_id`, `consent_version`, and `cookie_category_consent`.

---

## Phase 3 – Public Widget API & Minimal UI Shell

**Deliverables**
- `CookieBanner` widget in `lib/` with a minimal UI that:
  - Accepts the same high-level props as the React component: `domainUrl`, `environment`, `domainId`.
  - Loads configuration and consent state.
  - Renders a very simple footer banner with **Accept All** and **Reject All** buttons.

**Implementation Notes**
- Public API:
  - `CookieBanner({required String domainUrl, required String environment, int? domainId, BannerDesign? overrideDesign, ValueChanged<Map<int, bool>>? onConsentChanged, VoidCallback? onAcceptAll, VoidCallback? onRejectAll})`.
- Life cycle:
  1. On first build, generate or load `subjectIdentity` (UUID) using `dart:math`/`crypto` equivalent.
  2. Load stored consent via `ConsentStorage`.
  3. Fetch banner config via CDN → fallback API.
  4. Decide whether to show the banner (no consent / new cookies / version bump) – the full logic is in later phases, but we can start with **"no consent → show banner"**.
  5. Render a simple footer banner with the title, description, and two buttons.
- No complex layouts, categories, or languages yet; this phase only ensures the data pipeline, storage, and basic UI wiring are correct on mobile.

**Mobile Considerations**
- Use `MediaQuery` to respect safe areas on iOS (bottom notch) and Android gesture insets.
- Use Flutter buttons (`ElevatedButton`/`TextButton`) styled inline; no platform-specific widgets are required yet.

---

## Phase 4 – Full Consent Logic (Categories, Per-cookie, DNT, New Cookies)

**Deliverables**
- Full reproduction of React consent logic on mobile:
  - Category-level toggles: necessary, analytics, marketing, functional, performance.
  - Per-cookie toggles when users go into details.
  - Do Not Track behavior.
  - New cookie detection & consent versioning.

**Implementation Notes**
- Implement helpers in Dart equivalent to the React code:
  - `bool getConsentBySlug(Map<int, bool> consentsByCategory, String slug, UserDataProperties? data);`
  - `Map<int, bool> buildEffectiveConsent(Map<int, bool> raw, UserDataProperties? data, bool dntEnabled);`
  - `ConsentSnapshot buildSnapshotFromState(...);`
  - `bool hasNewCookiesOrVersionChange(ConsentSnapshot? stored, UserDataProperties current);`
- Do Not Track:
  - On **Flutter web**: read `window.navigator.doNotTrack` via `dart:html` and force marketing = denied if enabled.
  - On **mobile**: introduce an optional flag `respectDnt` and a DNT status field in the config if needed; by default the marketing category behavior is driven purely by user toggles.
- New Cookie Detection:
  - Store `available_cookies` and `consent_version` inside `ConsentSnapshot` (backed by `shared_preferences`).
  - When new API data arrives, compare the list and version; if there is a difference, treat it as **"consent invalid → show banner again"**.

**Mobile Considerations**
- Because there is no native cookie jar to purge, our SDK’s responsibility on mobile is to:
  - Persist and update consent state accurately.
  - Expose category decisions to the **host app** so it can enable/disable real SDKs (Firebase Analytics, Facebook SDK, etc.).
  - Optionally, provide helper utilities the host app can call to decide whether a given tracking call is allowed.

---

## Phase 5 – Rich UI: Wall Layout, Details Tab, About Tab, Floating Logo

**Deliverables**
- Wall layout (full-screen) with tabs: **Consent**, **Details**, **About**.
- Footer layout with expandable dialog into a wall-like view.
- Floating logo that appears after dismissal and can re-open preferences.

**Implementation Notes**
- Layouts:
  - Use `Stack` + `Positioned` for floating banner components.
  - Use `Dialog` / `showGeneralDialog` or a full-screen `Stack` overlay for the wall.
- Tabs and Navigation:
  - Represent `selectedNavItem` as an int or enum.
  - Implement a tab bar using `Row` + `GestureDetector` or `TabBar` inside a `DefaultTabController`.
- Data Binding:
  - Drive all labels, descriptions, and links from `BannerDesign` supplied by the backend.
  - Respect the `layoutType` (`wall` or `footer`) and button configuration (`buttonOrder`, `buttons`, `preferenceModalButtons`).
- Floating Logo:
  - Implement a `Draggable`/`GestureDetector` widget for drag behavior on mobile.
  - Persist last position per session only (in memory) or via `shared_preferences` if required.

**Mobile Considerations**
- Ensure performance on low-end Android devices by:
  - Minimizing rebuilds (use `ValueListenableBuilder`/`ChangeNotifier` or `StatefulWidget` with careful setState usage).
  - Avoiding heavy layouts when the banner is hidden.
- Respect platform back button behavior (e.g., Android back should close the wall banner if open).

---

## Phase 6 – Language, Translations & Device Info

**Deliverables**
- Multi-language support mirroring the web behavior.
- Device and browser/environment info collection for analytics.

**Implementation Notes**
- Languages:
  - Fetch `Language` list from API based on `domainId`.
  - Choose initial language based on:
    1. `BannerDesign.automaticLanguageDetection` flag.
    2. `WidgetsBinding.instance.platformDispatcher.locale.languageCode` (mobile locale).
  - Maintain `selectedLanguage` in state and switch `UserDataProperties` accordingly.
- Device Info (mobile):
  - Introduce `device_info_plus` (planned additional dependency) to gather:
    - OS name and version.
    - Device model.
  - Use `MediaQuery` to derive screen width/height.
  - Construct a `DeviceInfo` object that matches the backend contract and send it with consent updates and performance metrics.
- Device Info (web – optional):
  - For Flutter web builds, fall back to `dart:html` to read user agent and viewport info.

**Mobile Considerations**
- Use `device_info_plus` in a platform-safe way (guard web). The implementation can be in a `DeviceInfoCollector` service that uses conditional imports to separate mobile vs web.

---

## Phase 7 – Integration Hooks for Host App (Mobile SDK Behavior)

**Deliverables**
- Clear, documented integration points for mobile apps to **enforce** consent on their own SDKs.

**Implementation Notes**
- Expose callbacks from `CookieBanner`:
  - `onConsentChanged(Map<int, bool> consentByCategory)` – fired whenever user saves choices.
  - `onAcceptAll()` / `onRejectAll()` for simpler host logic.
- Provide a utility class:
  - `ConsentEvaluator` with methods like:
    - `bool isAnalyticsAllowed(ConsentSnapshot snapshot);`
    - `bool isMarketingAllowed(ConsentSnapshot snapshot);` etc.
- Document expected host behavior:
  - Host app listens for consent events and enables/disables:
    - Analytics SDKs (Firebase/GA, Segment, Mixpanel, etc.).
    - Marketing/ads SDKs.
    - Performance/monitoring SDKs.
  - For webviews or network layers that need the traditional cookie, the host can:
    - Read the stored `ConsentSnapshot` (JSON) from `ConsentStorage`.
    - Inject it as a cookie string or header in its own HTTP client as needed.

**Mobile Considerations**
- Our SDK does not directly manipulate other SDKs; instead it becomes the **single source of truth** for consent and exposes a clean API for the host.

---

## Phase 8 – Performance Metrics, Error Handling & Polish

**Deliverables**
- Performance metrics collection: API response time, banner display time, user reaction time.
- Robust error handling and graceful fallbacks.

**Implementation Notes**
- Performance:
  - Measure timestamps around CDN/API calls and banner visibility.
  - Post metrics to `/ucm/v2/banner/load-time` via `CookieBannerApiClient`.
- Error Handling:
  - If CDN/API fails, hide banner and optionally call an error callback; do not crash the app.
  - Log or expose errors via a debug flag for QA builds.
- UI Polish:
  - Skeleton loaders while data is loading.
  - Smooth show/hide animations for the banner.
  - Theming based on `BannerDesign` (colors, fonts, text size).

---

## Phase 9 – Testing, QA & Release Readiness

**Deliverables**
- Automated tests for core logic.
- Manual test checklist for iOS and Android.

**Implementation Notes**
- Unit Tests:
  - Consent building and evaluation.
  - New cookie detection.
  - Storage read/write (`SharedPreferencesConsentStorage`).
- Integration/Widget Tests:
  - Rendering banner under typical configurations.
  - Button flows: Accept all / Reject all / Allow selection.
- Manual QA:
  - Test on physical Android and iOS devices with different screen sizes.
  - Verify host app correctly turns third-party SDKs on/off based on consent.

---

## Summary of Mobile-specific Decisions

- **Consent Storage**: Use `shared_preferences` to store a JSON blob equivalent to the `gotrust_pb_ydt` cookie; add a browser-cookie implementation only for Flutter web.
- **Backend Compatibility**: All necessary consent data is sent explicitly in API bodies; we do not rely on auto-managed cookies.
- **Enforcement Model**: SDK exposes consent; host app enforces it on its own tracking SDKs and webviews.
- **Dynamic Configuration**: All environment, domain, and UI configuration comes from the host and backend, never hard-coded.
