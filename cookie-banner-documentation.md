# Cookie Banner Component - Technical Documentation

## Overview

This is a comprehensive **GDPR/CCPA-compliant Cookie Consent Banner** built with **React** and **TypeScript**. The component is designed to be embedded as a standalone bundle via `<script>` tag on any website, providing full cookie consent management capabilities with no external dependencies.

### Key Technologies
- **React** (with hooks)
- **TypeScript** (strongly typed)
- **Axios** (HTTP client)
- **js-cookie** (Cookie management)
- **react-device-detect** (Device detection)
- **react-responsive** (Responsive design)

---

## Architecture & Design Patterns

### Component Type
- **Functional Component** with React Hooks
- **Self-contained Bundle** - No external CSS dependencies
- **Inline Styling** - All styles managed internally for portability

### Bundle Requirements
```bash
# Build command
pnpm webpack --config webpack.cookie.config.js
```

⚠️ **Important**: Only standard HTML elements and inline CSS are used to maintain self-containment.

---

## Core Features

### 1. Cookie Consent Management

#### Consent Categories
The banner manages 5 distinct cookie categories:
- **Necessary** (always enabled, cannot be denied)
- **Analytics** (tracking and statistics)
- **Marketing** (advertising and remarketing)
- **Functional** (preferences and features)
- **Performance** (speed and monitoring)

#### Consent Actions
- ✅ **Accept All Cookies** - Grants consent to all categories
- ❌ **Reject All Cookies** - Denies all non-necessary cookies
- ⚙️ **Allow Selection** - Granular per-cookie/category control

### 2. Multi-Layout Support

#### Wall Layout
- Full-screen modal overlay
- Multi-tab navigation (Consent, Details, About)
- Detailed cookie information display
- Service grouping with expandable sections

#### Footer Layout
- Fixed bottom banner
- Compact design for mobile and desktop
- Dialog expansion for preferences
- Separate button configuration for modal view

### 3. Language & Translation System

#### Features
- **Multi-language support** via API
- **Automatic language detection** based on browser settings
- **Manual language selection** via dropdown
- **Dynamic translation loading** without page reload
- Loading states to prevent UI flicker

#### Supported Flow
1. Fetch available languages from API
2. Detect browser language automatically (if enabled)
3. User can manually switch languages
4. Translations fetched on-demand from CDN

### 4. Third-Party Integration Management

#### Google Tag Manager (GTM)
- **GTMConsentManager** class integration
- Consent mode v2 support
- Dynamic script loading based on consent
- Per-category consent updates

#### Adobe Launch
- **AdobeLaunchConsentManager** class integration
- Consent-based script loading
- Category-specific consent mapping

#### Cookie Blocking Manager
- **CookieBlockingManager** integration
- Prevents unauthorized cookie setting
- Intercepts `document.cookie` writes
- Domain-specific cookie management

### 5. GoTrust Shim Integration

#### Purpose
Runtime cookie enforcement layer that blocks/allows cookies based on user consent.

#### Key Functions
- `__gotrustShim.updateConsent(map)` - Update consent state
- `__gotrustShim.flushAllowed()` - Load pending scripts
- `__gotrustShim.revokeAll()` - Block all non-necessary tracking

#### Consent Persistence
Stores consent in `gotrust_pb_ydt` cookie with:
```json
{
  "subject_identity": "uuid",
  "domain_id": 123,
  "domain_url": "example.com",
  "consent_version": 1,
  "consented_cookies": ["cookie_id_1", "cookie_id_2"],
  "available_cookies": ["all_cookie_ids"],
  "category_choices": {
    "necessary": true,
    "analytics": false,
    "marketing": false,
    "functional": true,
    "performance": false
  }
}
```

### 6. Cookie Purging & Management

#### Automatic Cookie Deletion
When consent is denied for a category, associated cookies are **automatically deleted**.

#### Deletion Strategy
- **Multi-domain deletion**: Tries apex domain, subdomains, and host-only
- **Multi-path deletion**: Attempts all parent paths
- **SameSite variants**: Tests Lax, None+Secure
- **Safety guards**: Protected cookies (session, CSRF, auth) are never deleted

#### Tracker Detection
Only deletes cookies matching known tracker patterns:
```regex
/_ga|_gid|_gat|_gcl|_gac|_fbp|_fbc|_hj|hjSession|_clck|_clsk|fs_|dt|rx|mmapi|ajs_|amplitude_|_ttp|_pin_unauth|IDE|test_cookie|NID/
```

Protected patterns (never deleted):
```regex
/sessionid|PHPSESSID|csrftoken|XSRF-TOKEN|__Secure-|__Host-|gotrust_pb_ydt|auth|login|cart/
```

### 7. Do Not Track (DNT) Support

#### Behavior
- Detects browser DNT setting (`navigator.doNotTrack`)
- **Automatically denies marketing cookies** when DNT is enabled
- Overrides user preferences for marketing category
- Applies to all consent flows (accept all, custom selection)

### 8. Device & Browser Information Collection

#### Collected Data
```typescript
interface DeviceInfo {
  browserName: string;
  browserVersion: string;
  deviceType: string;
  osName: string;
  osVersion: string;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  mobileVendor?: string;
  mobileModel?: string;
  userAgent: string;
  screenWidth: number;
  screenHeight: number;
  viewportWidth: number;
  viewportHeight: number;
  devicePixelRatio: number;
}
```

#### Usage
- Sent to backend with every consent action
- Used for analytics and reporting
- Helps track user behavior patterns

### 9. New Cookie Detection System

#### Purpose
Automatically detects when new cookies are added to the domain and prompts user for re-consent.

#### Detection Logic
1. Stores list of available cookies at consent time in `gotrust_pb_ydt`
2. On subsequent visits, compares current API cookie list with stored list
3. If new cookies found OR consent version changed → Show banner again
4. User must re-consent to new cookies

#### Version Control
- `consent_version` field tracks cookie schema changes
- Server can bump version to force re-consent
- Prevents stale consent from covering new trackers

### 10. Performance Monitoring

#### Metrics Tracked
- **API Response Time**: Time from request to response
- **User Reaction Time**: Time from banner display to user action
- **Load Time**: Overall banner initialization time

#### Reporting
Sends performance metrics to backend via `/ucm/v2/banner/load-time` endpoint.

### 11. Responsive Design

#### Breakpoints
- **Small Mobile**: < 480px
- **Mobile**: < 767px
- **Tablet+**: ≥ 768px

#### Features
- Dynamic font sizes using `clamp()`
- Responsive button sizing
- Layout adaptation (wall vs footer)
- Touch-friendly controls on mobile

### 12. Floating Logo Feature

#### Functionality
- Shows after user dismisses banner
- Allows re-opening preferences
- Draggable on desktop
- Configurable via banner design settings
- Can be hidden/shown based on configuration

### 13. Google Font Loading

#### Dynamic Loading
- Loads custom fonts specified in banner configuration
- Only loads when functional consent is granted
- Fallback to system fonts
- Font loading respects consent preferences

---

## TypeScript Interfaces

### Core Data Structures

#### CookieConsent
```typescript
interface CookieConsent {
  category_id: number;
  consent_record_id: number;
  consent_status: boolean;
  cookie_id: number;
  service_id?: number;
}
```

#### CookieProperties
```typescript
interface CookieProperties {
  cookie_id: number;
  cookie_key: string;
  vendor_name: string;
  cookie_type: string;
  description: string;
  expiration: string;
  consent: boolean;
  consent_record_id: number;
  service_id?: number;
  category_id?: number;
  category_name?: string;
  domain_id?: number;
  consent_status?: boolean;
}
```

#### CategoryConsentRecordProperties
```typescript
interface CategoryConsentRecordProperties {
  services: ServiceProperties[];
  independent_cookies: CookieProperties[];
  category_id: number;
  category_name: string;
  category_description: string;
  category_necessary: boolean;
  is_marketing: boolean;
  category_unclassified: boolean;
  catefory_default_opt_out: boolean;
  domain_id: number;
  subject_identity: string;
}
```

#### BannerDesign
```typescript
interface BannerDesign {
  consentTabHeading: string;
  detailsTabHeading: string;
  aboutTabHeading: string;
  bannerHeading: string;
  bannerDescription: string;
  buttons?: BannerButtons;
  buttonStyles?: BannerButtonsStyles;
  buttonOrder?: ('deny' | 'allowSelection' | 'allowAll')[];
  // ... (extensive configuration options)
  layoutType: 'wall' | 'footer';
  showLanguageDropdown: boolean;
  automaticLanguageDetection: boolean;
  defaultOptIn: boolean;
  allowBannerClose: boolean;
}
```

---

## State Management

### useState Hooks (30+ state variables)

| State Variable | Type | Purpose |
|---------------|------|---------|
| `domainData` | `UserDataProperties[]` | All language variants of banner data |
| `isVisible` | `boolean` | Controls banner visibility |
| `showFloatingLogo` | `boolean` | Controls floating logo display |
| `selectedNavItem` | `number` | Active tab in wall layout |
| `countryCode` | `string` | User's country code (from IP) |
| `countryName` | `string` | User's country name |
| `continent` | `string` | User's continent |
| `domainId` | `number` | Domain identifier |
| `domainURL` | `string` | Current domain URL |
| `subjectIdentity` | `string` | Unique user identifier (UUID) |
| `translatedData` | `UserDataProperties` | Translated banner content |
| `cookies` | `CookieProperties[]` | List of all cookies |
| `isDialogOpen` | `boolean` | Preference dialog state |
| `ip` | `string` | User's IP address |
| `userConsent` | `{[cookieId: number]: boolean}` | Per-cookie consent state |
| `categoryConsent` | `{[categoryId: number]: boolean}` | Per-category consent state |
| `openCookieWallBanner` | `boolean` | Wall banner expansion state |
| `selectedLanguage` | `string` | Currently selected language code |
| `languages` | `Language[]` | Available languages |
| `gtmManager` | `GTMConsentManager \| null` | GTM integration instance |
| `adobeLaunchManager` | `AdobeLaunchConsentManager \| null` | Adobe integration instance |
| `deviceInfo` | `DeviceInfo \| null` | Collected device information |
| `cookieBlockingManager` | `CookieBlockingManager \| null` | Cookie blocking instance |
| `apiCookieUserData` | `UserDataProperties \| null` | Original API data |
| `localCookieUserData` | `UserDataProperties \| null` | Local state updates |
| `isAnimating` | `boolean` | Tab transition animation state |
| `contentKey` | `number` | Forces content re-render |
| `isLoadingTranslations` | `boolean` | Translation loading state |

### Computed State
```typescript
const cookieUserData = localCookieUserData || apiCookieUserData;
```
Uses local state if available, otherwise falls back to API data.

---

## useEffect Hooks & Side Effects

### 1. Global Function Exposure
```javascript
window.showGoTrustCookiePreferences = (value: boolean) => { /* ... */ }
```
Allows external code to programmatically open/close preferences.

### 2. Device Information Collection
Runs once on mount to collect browser and device data.

### 3. Automatic Language Detection
Detects browser language and switches if available and enabled.

### 4. Font Loading
Dynamically loads Google Fonts when functional consent is granted.

### 5. Geolocation Data Fetching
Fetches IP address and country information from API.

### 6. Cookie Detection & Banner Visibility
Checks for existing consent cookie and decides whether to show banner.

### 7. New Cookie Detection
Monitors for newly added cookies by comparing API data with stored consent.

### 8. Translation Fetching
Fetches translated content when language changes.

### 9. GTM Initialization
Creates GTM consent manager when configuration is loaded.

### 10. Adobe Launch Initialization
Creates Adobe Launch consent manager when configuration is loaded.

### 11. Cookie Blocking Manager Initialization
Sets up cookie interception when category data is loaded.

### 12. Consent State Initialization
Seeds toggles from stored consent + API data.

### 13. Post-Consent Vendor Loading
Loads GTM/Adobe scripts after consent is granted.

### 14. Language List Fetching
Fetches available languages for the domain.

---

## API Integration

### Base URL
Configurable via `environment` prop (dev/staging/production)

### Endpoints

#### 1. IP Geolocation
```
GET https://api.ipify.org?format=json
GET {baseURL}/backend/api/v3/gt/ip-info/{ip}
```
**Purpose**: Get user's IP and geographic location

**Response**:
```json
{
  "country_code": "US",
  "country": "United States",
  "continent": "North America"
}
```

#### 2. CDN Banner Data (Primary)
```
GET https://d1axzsitviir9s.cloudfront.net/banner/{domainURL}_{domainId}.json
```
**Purpose**: Fetch pre-generated banner configuration from CDN

**Response**: Array of `UserDataProperties` (one per language)

#### 3. Banner Data (Fallback)
```
GET {baseURL}/ucm/v2/banner/display?domain_id={id}&subject_identity={uuid}&country_name={country}
```
**Purpose**: Dynamic banner configuration from API

#### 4. Consent Update
```
PUT {baseURL}/ucm/banner/record-status-update
```
**Purpose**: Save user consent choices

**Request Body**:
```json
{
  "domain_id": 123,
  "subject_identity": "uuid",
  "geolocation": "1.2.3.4(US)",
  "continent": "North America",
  "country": "United States",
  "source": "web",
  "cookie_category_consent": [
    {
      "category_id": 1,
      "consent_record_id": 456,
      "consent_status": true,
      "cookie_id": 789,
      "service_id": 101
    }
  ],
  "device_info": { /* ... */ }
}
```

#### 5. Performance Metrics
```
POST {baseURL}/ucm/v2/banner/load-time
```
**Purpose**: Report API response time and user reaction time

**Request Body**:
```json
{
  "domain_id": 123,
  "subject_identity": "uuid",
  "load_time": 245.67,
  "response_time": 3421.89
}
```

#### 6. Available Languages
```
GET {baseURL}/ucm/v2/domain/languages?domain_id={id}
```
**Purpose**: Fetch list of available languages for translation

#### 7. Horizontal Banner (Legacy)
```
GET {baseURL}/ucm/banner/horizontal-banner?domain_url={url}&domain_id={id}
```
**Purpose**: Fetch cookie list for domain (appears unused in current flow)

---

## Key Functions

### Consent Management

#### `handleAcceptAllCookies()`
- Grants consent to all categories
- Updates GoTrust shim
- Flushes pending scripts
- Persists consent cookie
- Triggers GTM/Adobe updates
- Updates cookie blocking manager

#### `handleRejectAllCookies()`
- Denies all non-necessary cookies
- Revokes all shim permissions
- Purges Google Analytics cookies
- Deletes denied category cookies
- Updates all consent managers
- Persists minimal consent

#### `handleAllowSelection()`
- Saves user's granular choices
- Opens details tab if not already there
- Updates consent based on toggles
- Purges denied cookies
- Syncs with all managers
- Handles necessary cookie enforcement

### Cookie Operations

#### `persistConsentCookie()`
Saves the `gotrust_pb_ydt` cookie with:
- Subject identity
- Domain ID and URL
- Consent version
- Consented cookie IDs
- Available cookie IDs (for new cookie detection)
- Category choices map

#### `purgeCookiesForDeniedCategories()`
- Identifies cookies belonging to denied categories
- Calls `deleteCookieEverywhere()` for each
- Special handling for Google Analytics cookies

#### `deleteCookieEverywhere()`
- Safety checks against protected cookies
- Only deletes known tracker patterns
- Tries multiple domain/path/SameSite combinations
- Ensures complete cookie removal

#### `purgeGoogleAnalyticsCookies()`
- Specifically targets `_ga`, `_gid`, `_gat`, `_ga_*` cookies
- Comprehensive deletion across all domains/paths

### Data Management

#### `fetchUserDataCDN()`
- Primary data fetching method
- Uses CloudFront CDN for performance
- Loads all language variants
- Sets API data state
- Triggers new cookie detection

#### `fetchUserData()`
- Fallback API method
- Used when CDN unavailable
- Tracks performance metrics
- Sets API data state

#### `getTranslatedData()`
- Fetches translations for selected language
- Shows loading state
- Switches banner content without refetch

#### `checkForNewCookies()`
- Compares stored consent with current API data
- Checks consent version changes
- Detects truly new cookies
- Shows banner if updates found

### State Updates

#### `updateLocalConsentState()`
- Updates local state without API call
- Prevents triggering new cookie detection
- Maps consent array to cookie properties
- Updates localStorage

#### `setUserConsentCookies()`
- Updates total_cookies in localStorage
- Includes consent status in stored data

#### `setCategoryConsentStatus()`
- Updates total_categories in localStorage
- Determines consent from cookie states

### Helper Functions

#### `getConsentBySlug()`
- Maps category slugs to consent status
- Handles necessary (always true)
- Uses smart fallbacks for category matching
- Supports is_marketing flag and name patterns

#### `buildEffectiveConsent()`
- Applies DNT overrides to marketing
- Forces necessary categories to true
- Returns cleaned consent map

#### `pushConsentToShim()`
- Converts category consent to shim format
- Calls `__gotrustShim.updateConsent()`
- Flushes allowed scripts

#### `loadVendorsAfterConsent()`
- Conditionally loads GTM/Adobe
- Only loads if non-necessary consent granted
- Updates managers with current consent

#### `collectDeviceInfo()`
- Gathers comprehensive device data
- Calculates viewport dimensions
- Returns structured DeviceInfo object

#### `onBannerVisible()` / `onBannerButtonClick()`
- Performance tracking helpers
- Measures API response time
- Measures user reaction time

---

## Component Props

```typescript
interface CookieBannerProps {
  domainUrl: string;       // The website domain
  environment: string;     // API base URL (dev/staging/prod)
  domain_id?: number;      // Optional domain identifier
}
```

### Usage Example
```html
<script>
  const root = ReactDOM.createRoot(document.getElementById('gotrust-banner'));
  root.render(
    <CookieBanner 
      domainUrl="example.com" 
      environment="https://api.gotrust.tech"
      domain_id={123}
    />
  );
</script>
```

---

## UI Components

### Wall Banner
- **Full-screen modal** with backdrop
- **Tabbed navigation**: Consent / Details / About
- **Logo display** with configurable size
- **Language dropdown** selector
- **Close button** (if enabled)
- **Service expansion** accordions
- **Category toggles** with descriptions
- **Action buttons** at bottom

### Footer Banner
- **Fixed bottom bar**
- **Compact description** with truncation
- **Quick action buttons**
- **Dialog for preferences** (opens wall-like view)
- **Mobile-optimized** layout

### Floating Logo
- **Draggable** on desktop
- **Fixed position** on mobile
- **Clickable** to reopen preferences
- **Configurable** via banner design

### Loading States
- **Wall Banner Loader**: Skeleton UI with shimmer effect
- **Footer Banner Loader**: Spinner with loading text
- **Translation Loading**: Shows skeleton during language switch

---

## Styling & Theming

### Dynamic Styling
All styles are applied inline and controlled via banner configuration:

```typescript
{
  backgroundColor: string;
  fontColor: string;
  textSize: 'small' | 'medium' | 'large';
  fontFamily: string;
  buttonColor: string;
  colorScheme: string;
  logoUrl: string;
  logoSize: { width: string; height: string };
}
```

### Responsive Fonts
```css
fontSize: clamp(11px, 1.05vw, 13px);
height: clamp(32px, 5.2vw, 44px);
```

### Button Ordering
Configurable button order via `buttonOrder` array:
```typescript
buttonOrder: ['deny', 'allowSelection', 'allowAll']
```

### Separate Modal Buttons (Footer Layout)
- `preferenceModalButtons`: Different button config for dialog
- `preferenceModalButtonOrder`: Different order for dialog
- `preferenceModalButtonStyles`: Different styles for dialog

---

## Security & Privacy

### Protected Cookies
Never deletes critical cookies:
- Session identifiers
- CSRF tokens
- Authentication tokens
- Shopping cart data
- GoTrust consent cookie

### UUID Generation
Uses secure random UUID v4 for subject identity:
```typescript
crypto.randomUUID() || fallback_to_crypto.getRandomValues()
```

### SameSite & Secure
- Respects HTTPS for Secure flag
- Uses SameSite=Lax for consent cookie
- Handles localhost development mode

### DNT Compliance
- Respects browser Do Not Track setting
- Automatically denies marketing when DNT enabled
- Cannot be overridden by user

---

## Browser Compatibility

### Modern Features Used
- `crypto.randomUUID()` with fallback
- `Intl` for internationalization
- `localStorage` for data persistence
- `IntersectionObserver` (if used in managers)
- ES6+ syntax (classes, async/await, arrow functions)

### Polyfills Required
May need polyfills for:
- IE11 (if support required)
- Older Safari versions
- Legacy Edge

---

## Data Flow Diagram

```
1. Page Load
   ↓
2. Fetch IP → Get Country
   ↓
3. Check gotrust_pb_ydt Cookie
   ↓
4a. Cookie Exists              4b. No Cookie
    ↓                              ↓
    Fetch CDN Data                 Generate UUID
    ↓                              ↓
    Check New Cookies              Fetch CDN Data
    ↓                              ↓
    If New: Show Banner            Show Banner
    ↓                              ↓
5. User Interaction
   ↓
6. Accept/Reject/Custom
   ↓
7. Update GoTrust Shim
   ↓
8. Purge Denied Cookies
   ↓
9. Update GTM/Adobe/Blocking Manager
   ↓
10. POST Consent to API
    ↓
11. Set gotrust_pb_ydt Cookie
    ↓
12. Hide Banner / Show Floating Logo
```

---

## localStorage Usage

### Keys Stored

#### `total_cookies`
Array of all cookies with consent status
```json
[
  {
    "cookie_id": 1,
    "cookie_key": "_ga",
    "consent": true,
    "consent_status": true,
    // ... other properties
  }
]
```

#### `total_categories`
Array of categories with consent status
```json
[
  {
    "category_id": 1,
    "category_name": "Analytics",
    "consent_status": true
  }
]
```

---

## Error Handling

### API Errors
- Axios error interception
- Logs status code and message
- Graceful degradation (continues with cached data)

### Translation Errors
- Falls back to English
- Clears loading state
- Logs error without blocking UI

### Manager Initialization Errors
- Try-catch blocks around each manager
- Logs errors but doesn't break consent flow
- Managers are optional features

---

## Performance Optimizations

### 1. CDN Loading
Primary data source is CloudFront CDN for fast global access

### 2. Lazy Script Loading
GTM and Adobe scripts only load after consent granted

### 3. Image Decode Gate
Uses `useDecodeGate` hook to wait for logo decoding before showing banner (prevents layout shift)

### 4. Debounced State Updates
Animations use timeouts to prevent excessive re-renders

### 5. Memoized Computations
Some computed values use `useMemo` and `useCallback`

### 6. Conditional Rendering
Only renders active tab content, not all tabs simultaneously

---

## Testing Considerations

### Unit Test Scenarios
- UUID generation and validation
- Consent map building
- Cookie purging logic
- Category slug matching
- DNT enforcement

### Integration Test Scenarios
- API response handling
- State synchronization
- Manager initialization
- Translation loading
- Cookie persistence

### E2E Test Scenarios
- Accept all flow
- Reject all flow
- Custom selection flow
- Language switching
- New cookie detection
- Reopening preferences

---

## Known Limitations & Future Improvements

### Current Limitations
1. Translation API commented out (using CDN pre-translation)
2. Some API endpoints appear unused (horizontal-banner)
3. Ping functionality commented out
4. No retry logic for failed API calls

### Potential Improvements
1. Add retry mechanism for API failures
2. Implement service worker for offline support
3. Add unit tests and integration tests
4. Reduce bundle size through code splitting
5. Add accessibility improvements (ARIA labels, keyboard nav)
6. Implement cookie scanning for truly dynamic detection

---

## Configuration Examples

### Minimal Configuration
```json
{
  "bannerDesign": {
    "layoutType": "footer",
    "bannerHeading": "We use cookies",
    "bannerDescription": "We use cookies to improve your experience.",
    "backgroundColor": "#ffffff",
    "fontColor": "#000000",
    "buttonColor": "#0066cc"
  }
}
```

### Advanced Configuration
```json
{
  "bannerDesign": {
    "layoutType": "wall",
    "showLogo": "true",
    "logoUrl": "https://cdn.example.com/logo.png",
    "showLanguageDropdown": true,
    "automaticLanguageDetection": true,
    "defaultOptIn": false,
    "allowBannerClose": true,
    "buttonOrder": ["allowAll", "allowSelection", "deny"],
    "preferenceModalButtonOrder": ["deny", "allowSelection", "allowAll"]
  },
  "gtmConfiguration": {
    "enabled": true,
    "containerId": "GTM-XXXXX",
    "consentMode": "v2"
  },
  "adobeLaunchConfiguration": {
    "enabled": true,
    "scriptUrl": "https://assets.adobedtm.com/..."
  }
}
```

---

## Deployment Checklist

- [ ] Build bundle with webpack
- [ ] Test on target domain
- [ ] Verify API endpoints are accessible
- [ ] Configure CDN banner data
- [ ] Test all consent flows
- [ ] Verify cookie deletion works
- [ ] Test GTM/Adobe integration
- [ ] Check mobile responsiveness
- [ ] Verify language switching
- [ ] Test new cookie detection
- [ ] Validate DNT handling
- [ ] Check performance metrics

---

## Conclusion

This Cookie Banner component is a **production-ready, enterprise-grade consent management solution** that handles:

✅ GDPR/CCPA compliance  
✅ Multi-language support  
✅ Third-party tag management  
✅ Granular cookie control  
✅ Responsive design  
✅ Performance tracking  
✅ Device fingerprinting  
✅ Automatic cookie purging  
✅ DNT compliance  
✅ New cookie detection  

The component is designed for **seamless integration** into any website via a simple script tag, with **zero external dependencies** in the final bundle.

---

**Document Version**: 1.0  
**Last Updated**: January 12, 2026  
**Component Version**: Based on provided source code
