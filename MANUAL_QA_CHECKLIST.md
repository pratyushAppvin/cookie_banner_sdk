# Cookie Banner SDK - Manual QA Checklist

This checklist provides a comprehensive guide for manual testing of the Cookie Banner SDK on iOS and Android devices.

## Test Environment Setup

### Prerequisites
- [ ] iOS device or simulator (iOS 13+)
- [ ] Android device or emulator (Android 5.0+)
- [ ] Valid domain configuration with backend API
- [ ] Test domain ID and URL configured

### Test Configuration
- **Test Domain ID**: _________
- **Test Domain URL**: _________
- **Environment URL**: _________
- **Tester Name**: _________
- **Date**: _________

---

## Phase 1: Banner Display & Loading

### Initial Load
- [ ] Banner appears on first app launch
- [ ] Skeleton loader shows during initialization
- [ ] Banner displays correct content from CDN/API
- [ ] No console errors during load
- [ ] Performance metrics are sent successfully

### Layout Types
- [ ] **Footer Banner**: Displays at bottom of screen
- [ ] **Wall Banner**: Displays as full-screen overlay
- [ ] Banner respects safe areas on notched devices
- [ ] Banner is scrollable when content overflows

### Theming & Styling
- [ ] Background color matches configuration
- [ ] Font color matches configuration
- [ ] Button color matches configuration
- [ ] Font family is applied correctly
- [ ] Text size (small/medium/large) renders correctly
- [ ] Logo displays when configured
- [ ] Logo has correct dimensions

---

## Phase 2: Button Interactions

### Accept All Button
- [ ] "Accept All" button is visible
- [ ] Clicking "Accept All" closes banner
- [ ] All categories are set to true in storage
- [ ] Floating logo appears after accept (if configured)
- [ ] Banner does not reappear on app restart
- [ ] Performance metrics track user reaction time

### Reject All Button
- [ ] "Reject All" button is visible
- [ ] Clicking "Reject All" closes banner
- [ ] Only necessary categories are set to true
- [ ] Non-necessary categories are set to false
- [ ] Banner does not reappear on app restart

### Allow Selection Button
- [ ] "Allow Selection" button is visible
- [ ] Opens consent preferences dialog
- [ ] Dialog displays all category options
- [ ] Dialog is dismissible with back button/gesture

### Button Order
- [ ] Buttons appear in configured order
- [ ] Single-button layout uses full width
- [ ] Multi-button layout wraps appropriately
- [ ] Buttons are accessible on small screens

---

## Phase 3: Consent Preferences Dialog

### Category Toggles
- [ ] All categories are listed
- [ ] Necessary categories cannot be toggled off
- [ ] Non-necessary categories can be toggled
- [ ] Toggle states persist during session
- [ ] Visual indication for necessary vs optional

### Per-Cookie Details
- [ ] Details tab shows cookie breakdown
- [ ] Each service is listed with description
- [ ] Individual cookies can be toggled
- [ ] Cookie descriptions are readable
- [ ] Toggling cookie updates category state
- [ ] Markdown formatting renders correctly

### About Tab
- [ ] About tab displays legal information
- [ ] Privacy policy link works (if configured)
- [ ] Cookie policy link works (if configured)
- [ ] Content is scrollable
- [ ] Markdown links are clickable

### Save & Close
- [ ] "Save Choices" button saves preferences
- [ ] Close button dismisses dialog
- [ ] Saved choices persist after app restart
- [ ] Backend receives consent update

---

## Phase 4: Language Support

### Auto-Detection
- [ ] Device language is detected correctly
- [ ] Banner content matches device language (if available)
- [ ] Falls back to default language if unavailable
- [ ] Auto-detection respects configuration flag

### Manual Selection
- [ ] Language dropdown appears (if configured)
- [ ] All available languages are listed
- [ ] Language icon/flag displays correctly
- [ ] Selecting language updates all content immediately
- [ ] Selected language persists during session

### Language in Wall Banner
- [ ] Language selector appears in header
- [ ] Selector does not overlap close button
- [ ] Selector is visible and accessible

### Language in Footer Banner
- [ ] Language selector appears above buttons
- [ ] Selector aligns properly
- [ ] Does not interfere with button interactions

---

## Phase 5: Do Not Track (DNT)

### DNT Enabled
- [ ] Marketing category is forced to false
- [ ] Marketing cookies cannot be enabled
- [ ] UI indicates DNT is active (if applicable)
- [ ] Other categories remain controllable

### DNT Disabled
- [ ] All categories can be controlled normally
- [ ] No restrictions on marketing consent

---

## Phase 6: New Cookie Detection

### Version Change
- [ ] Banner reappears when consent version changes
- [ ] Previous choices are pre-selected
- [ ] User can review and update choices
- [ ] New version is saved correctly

### New Cookies Added
- [ ] Banner reappears when new cookies are detected
- [ ] New cookies default to unconsented state
- [ ] Existing choices are preserved
- [ ] User can consent to new cookies

---

## Phase 7: Floating Logo

### Logo Appearance
- [ ] Logo appears after banner is dismissed (if configured)
- [ ] Logo is draggable across screen
- [ ] Logo stays within screen bounds
- [ ] Logo position persists during session

### Logo Interaction
- [ ] Tapping logo reopens banner
- [ ] Logo disappears when banner is shown
- [ ] Logo has appropriate size
- [ ] Logo renders correctly (image loads)

---

## Phase 8: Error Handling

### Network Errors
- [ ] CDN failure falls back to API gracefully
- [ ] API failure hides banner without crash
- [ ] Error callback fires (if configured)
- [ ] App continues to function normally

### Invalid Configuration
- [ ] Invalid domain ID handled gracefully
- [ ] Missing required fields don't cause crashes
- [ ] Malformed JSON is handled
- [ ] Empty/null responses are handled

### Storage Errors
- [ ] SharedPreferences unavailable is handled
- [ ] Corrupted storage data is recovered
- [ ] Clear consent works even if corrupted

---

## Phase 9: Platform-Specific Tests

### iOS Specific
- [ ] Safe area insets respected (notch, home indicator)
- [ ] Dark mode support (if applicable)
- [ ] Landscape orientation works
- [ ] iPad layout is appropriate
- [ ] VoiceOver accessibility (if applicable)
- [ ] Dynamic Type support (if applicable)

### Android Specific
- [ ] System navigation bar avoided
- [ ] Material design guidelines followed
- [ ] Back button dismisses dialog appropriately
- [ ] Various screen sizes/densities work
- [ ] TalkBack accessibility (if applicable)
- [ ] Android 12+ splash screen compatibility

---

## Phase 10: Performance & Memory

### Load Times
- [ ] Banner initializes in < 2 seconds (CDN)
- [ ] API fallback completes in < 5 seconds
- [ ] No ANR (Application Not Responding) on Android
- [ ] No UI freezing on iOS

### Memory Usage
- [ ] No memory leaks when opening/closing banner
- [ ] Images are properly released
- [ ] Dialog disposal is clean
- [ ] Multiple open/close cycles don't increase memory

### Metrics Collection
- [ ] CDN response time is recorded
- [ ] API fallback time is recorded
- [ ] Banner display time is recorded
- [ ] User reaction time is recorded
- [ ] Metrics are sent to backend
- [ ] Device info is included

---

## Phase 11: Integration Testing

### Host App Callbacks
- [ ] `onConsentChanged` fires with correct data
- [ ] `onAcceptAll` callback fires
- [ ] `onRejectAll` callback fires
- [ ] `onError` callback fires on errors
- [ ] Callbacks provide accurate information

### ConsentEvaluator Usage
- [ ] `isAnalyticsAllowed()` returns correct value
- [ ] `isMarketingAllowed()` returns correct value
- [ ] `isFunctionalAllowed()` returns correct value
- [ ] `isPerformanceAllowed()` returns correct value
- [ ] `hasConsent()` works correctly
- [ ] `getAllowedCategoryIds()` returns correct list

### Storage Integration
- [ ] Host app can read consent from storage
- [ ] Consent format is compatible with web version
- [ ] UUID is consistent across sessions
- [ ] Clear consent works from host app

---

## Phase 12: Edge Cases

### Rapid Interactions
- [ ] Multiple button clicks don't cause issues
- [ ] Rapid open/close doesn't crash
- [ ] Toggle spamming is handled gracefully

### Low Memory
- [ ] App doesn't crash under memory pressure
- [ ] Banner can be dismissed to free memory
- [ ] Images are released when not visible

### Network Conditions
- [ ] Slow network doesn't hang UI
- [ ] Offline mode is handled
- [ ] Connection changes during load

### Device Rotation
- [ ] Banner adjusts to portrait
- [ ] Banner adjusts to landscape
- [ ] No data loss during rotation
- [ ] Dialog survives rotation

---

## Sign-Off

### Test Summary
- **Total Tests**: ______
- **Passed**: ______
- **Failed**: ______
- **Blocked**: ______

### Critical Issues Found
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

### Non-Critical Issues Found
1. _________________________________________________
2. _________________________________________________
3. _________________________________________________

### Recommendations
_________________________________________________________
_________________________________________________________
_________________________________________________________

### Tester Approval
- **Name**: _________
- **Signature**: _________
- **Date**: _________

### Product Owner Approval
- **Name**: _________
- **Signature**: _________
- **Date**: _________

---

## Notes

- Mark items as **Pass**, **Fail**, or **N/A**
- Document failures with screenshots and steps to reproduce
- Test on minimum 2 iOS devices and 2 Android devices
- Test on both physical devices and simulators/emulators
- Include various screen sizes (small phone, large phone, tablet)
- Test with different backend configurations
- Verify all changes are committed to version control before sign-off
