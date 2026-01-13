# Running the Cookie Banner Demo App

## ✅ Demo App Integration Complete!

The main.dart file has been updated with a comprehensive demo app that showcases all Cookie Banner SDK features.

## 🚀 How to Run

### Option 1: Run on Android Emulator (Recommended for Testing)
```bash
flutter run -d emulator-5554
```

### Option 2: Run on macOS Desktop
```bash
flutter run -d macos
```

### Option 3: Run on Chrome (Web)
```bash
flutter run -d chrome
```

## ⚙️ Configuration Required

Before running, you need to configure your domain settings in [lib/main.dart](lib/main.dart) (lines 289-292):

```dart
CookieBanner(
  domainUrl: 'example.com',              // ⚠️ Replace with your domain
  environment: 'https://api.gotrust.io', // ⚠️ Replace with your API URL
  domainId: 123,                         // ⚠️ Replace with your domain ID
  ...
)
```

### Where to Get These Values:
- **domainUrl**: Your website/app domain (e.g., "myapp.com")
- **environment**: Your backend API base URL
- **domainId**: Numeric ID from your backend/dashboard

## 🎯 Demo App Features

### 1. Consent Status Display
- Shows current consent state
- Visual indicators for each cookie category
- Real-time updates when consent changes

### 2. Interactive Cookie Banner
The banner appears:
- ✅ On first launch (no stored consent)
- ✅ When consent is cleared
- ✅ When new cookies are detected
- ✅ When consent version changes

### 3. Three Interaction Options
- **Accept All**: Enables all cookie categories
- **Reject All**: Enables only necessary cookies
- **Allow Selection**: Opens detailed preferences dialog

### 4. Detailed Preferences Dialog
- Category-level toggles
- Per-cookie granular control
- Service grouping
- Cookie descriptions and expiration info
- About tab with legal information

### 5. Consent Details View
Shows for each category:
- ✅ Necessary (always enabled)
- 📊 Analytics
- 📢 Marketing
- 🔧 Functional
- ⚡ Performance

### 6. Consent Summary
- Total categories count
- Allowed categories count
- Allowed cookies count
- Overall status (Accepted All / Rejected All / Custom)

### 7. Clear Consent Button
- Clears stored consent
- Forces banner to reappear
- Useful for testing different consent flows

## 📱 Testing Guide

### First Launch Test
1. Run the app for the first time
2. Cookie banner should appear automatically
3. Try "Accept All" - see all categories enabled
4. Check consent details on main screen

### Reject All Test
1. Clear consent using the button
2. Restart app
3. Click "Reject All" on banner
4. Verify only necessary cookies enabled

### Custom Selection Test
1. Clear consent and restart
2. Click "Allow Selection"
3. Toggle individual categories
4. Click "Save Choices"
5. Verify your selections on main screen

### Language Support Test
1. Wall banner has language selector in header
2. Try switching languages
3. All content updates dynamically

### Floating Logo Test
1. After dismissing banner, floating logo appears
2. Drag it around the screen
3. Tap it to reopen preferences

## 🔍 What to Look For

### ✅ Success Indicators
- Banner appears with your configured design
- All buttons work correctly
- Consent is saved and persists across app restarts
- Callbacks fire (check console logs)
- No error messages

### ⚠️ Common Issues

#### Banner Doesn't Appear
- **Solution**: Clear consent or uninstall/reinstall app
- Consent is stored in SharedPreferences

#### "Failed to load banner configuration" Error
- **Solution**: Check your domainUrl, environment, and domainId
- Verify backend API is accessible
- Check console for network errors

#### Blank Banner
- **Solution**: Verify backend returns valid BannerDesign JSON
- Check CDN/API endpoints are correct

## 📊 Console Logs

The demo app logs useful information:

```
📊 Consent changed: {1: true, 2: true, 3: false, 4: true, 5: true}
✅ Analytics enabled
✅ User accepted all cookies
```

These logs help you understand:
- When consent changes
- Which categories are enabled/disabled
- Callback execution flow

## 🎨 UI Highlights

### Main Screen
- Material Design 3
- Card-based layout
- Color-coded consent status
- Responsive to screen size

### Cookie Banner
- Supports both Wall and Footer layouts
- Configurable colors, fonts, buttons
- Smooth animations (300ms fade)
- Professional skeleton loaders

### Preferences Dialog
- Tabbed interface (Consent / Details / About)
- Expandable categories
- Toggle switches for each cookie
- Markdown support for descriptions

## 🔄 Development Workflow

### Making Changes
1. Edit code in VS Code or your IDE
2. Hot reload: Press `r` in terminal or save file
3. Hot restart: Press `R` for full restart
4. Changes apply immediately without losing app state

### Testing Different Scenarios
1. Use "Clear Consent" button to reset
2. Restart app to see banner again
3. Try different consent combinations
4. Verify ConsentEvaluator methods work correctly

## 📚 Integration Examples

### Check Analytics Permission
```dart
if (ConsentEvaluator.isAnalyticsAllowed(_currentConsent)) {
  // Enable Firebase Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
}
```

### Check Marketing Permission
```dart
if (ConsentEvaluator.isMarketingAllowed(_currentConsent)) {
  // Enable Facebook Ads
  await FacebookAds.initialize();
}
```

### Listen to Changes
```dart
CookieBanner(
  onConsentChanged: (consent) {
    // Update your tracking SDKs
    updateTrackingSDKs(consent);
  },
)
```

## 🎯 Next Steps

1. **Configure Your Domain**: Update domainUrl, environment, domainId
2. **Run the App**: Choose a device and execute `flutter run`
3. **Test All Flows**: Accept All, Reject All, Custom Selection
4. **Integrate with Your SDKs**: Use ConsentEvaluator in your app
5. **Follow Integration Guide**: See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

## 📖 Additional Resources

- **Integration Guide**: [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Third-party SDK integration examples
- **QA Checklist**: [MANUAL_QA_CHECKLIST.md](MANUAL_QA_CHECKLIST.md) - Comprehensive testing guide
- **Project Summary**: [PROJECT_COMPLETION_SUMMARY.md](PROJECT_COMPLETION_SUMMARY.md) - Full feature list
- **Development Plan**: [cookie-banner-sdk-phased-plan.md](cookie-banner-sdk-phased-plan.md) - Implementation details

## ❓ Troubleshooting

### App Won't Start
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

### Analyzer Errors
```bash
# Check for issues
flutter analyze
```

### Test Failures
```bash
# Run tests
flutter test
```

### Network Issues
- Ensure device/emulator has internet connection
- Check firewall settings
- Verify API endpoints are accessible

---

**🎉 Your Cookie Banner SDK demo app is ready to run!**

Start with: `flutter run -d emulator-5554` (or your preferred device)
