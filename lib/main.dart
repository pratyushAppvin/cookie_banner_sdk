import 'package:flutter/material.dart';
import 'package:cookie_banner_sdk/cookie_banner_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cookie Banner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CookieBannerDemoPage(),
    );
  }
}

class CookieBannerDemoPage extends StatefulWidget {
  const CookieBannerDemoPage({super.key});

  @override
  State<CookieBannerDemoPage> createState() => _CookieBannerDemoPageState();
}

class _CookieBannerDemoPageState extends State<CookieBannerDemoPage> {
  ConsentSnapshot? _currentConsent;
  String _statusMessage = 'No consent given yet';
  final _storage = SharedPreferencesConsentStorage();

  @override
  void initState() {
    super.initState();
    _loadStoredConsent();
  }

  Future<void> _loadStoredConsent() async {
    final consent = await _storage.loadConsent();
    setState(() {
      _currentConsent = consent;
      if (consent != null) {
        _statusMessage = 'Consent loaded from storage';
      }
    });
  }

  Future<void> _clearConsent() async {
    await _storage.clearConsent();
    setState(() {
      _currentConsent = null;
      _statusMessage = 'Consent cleared - banner will show on restart';
    });
    
    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consent cleared! Restart the app to see the banner again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Cookie Banner Demo'),
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _currentConsent != null
                                  ? Icons.check_circle
                                  : Icons.info_outline,
                              color: _currentConsent != null
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Consent Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Current Consent Details
                if (_currentConsent != null) ...[
                  const Text(
                    'Current Consent Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildConsentCard(
                    'Necessary Cookies',
                    ConsentEvaluator.isNecessaryAllowed(_currentConsent),
                    'Always enabled for core functionality',
                    Icons.security,
                  ),
                  _buildConsentCard(
                    'Analytics Cookies',
                    ConsentEvaluator.isAnalyticsAllowed(_currentConsent),
                    'Used to understand how you use our app',
                    Icons.analytics,
                  ),
                  _buildConsentCard(
                    'Marketing Cookies',
                    ConsentEvaluator.isMarketingAllowed(_currentConsent),
                    'Used to show you relevant advertisements',
                    Icons.campaign,
                  ),
                  _buildConsentCard(
                    'Functional Cookies',
                    ConsentEvaluator.isFunctionalAllowed(_currentConsent),
                    'Enable enhanced features and personalization',
                    Icons.extension,
                  ),
                  _buildConsentCard(
                    'Performance Cookies',
                    ConsentEvaluator.isPerformanceAllowed(_currentConsent),
                    'Help us improve app performance',
                    Icons.speed,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Consent Summary
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consent Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Total Categories',
                            '5',
                          ),
                          _buildSummaryRow(
                            'Allowed Categories',
                            ConsentEvaluator.getAllowedCategorySlugs(_currentConsent)
                                .length
                                .toString(),
                          ),
                          _buildSummaryRow(
                            'Allowed Cookies',
                            ConsentEvaluator.getAllowedCookieIds(_currentConsent)
                                .length
                                .toString(),
                          ),
                          _buildSummaryRow(
                            'Status',
                            ConsentEvaluator.hasAcceptedAll(_currentConsent)
                                ? 'Accepted All'
                                : ConsentEvaluator.hasRejectedAll(_currentConsent)
                                    ? 'Rejected All (Necessary Only)'
                                    : 'Custom Selection',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Clear Consent Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearConsent,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear Consent & Show Banner Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.cookie, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No Consent Given Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The cookie banner will appear on first launch.\nInteract with it to save your preferences.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Information Card
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'How to Test',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('1. Configure your domainUrl, environment, and domainId in the CookieBanner widget below'),
                        const SizedBox(height: 8),
                        const Text('2. The banner appears on first launch or when consent is cleared'),
                        const SizedBox(height: 8),
                        const Text('3. Click "Accept All", "Reject All", or "Allow Selection" to customize'),
                        const SizedBox(height: 8),
                        const Text('4. Your preferences are saved and displayed above'),
                        const SizedBox(height: 8),
                        const Text('5. Click "Clear Consent" to reset and see the banner again'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 100), // Space for banner
              ],
            ),
          ),
          
          // Cookie Banner Widget
          CookieBanner(
            // CONFIGURE THESE VALUES FOR YOUR DOMAIN
            domainUrl: 'https://www.gotrust.tech/',  // Replace with your domain
            environment: 'https://dev.gotrust.tech',  // Your API base URL
            domainId: 198,  // Replace with your domain ID
            
            // Optional: Respect Do Not Track
            respectDnt: false,
            
            // Callback when consent changes
            onConsentChanged: (consentByCategory) {
              setState(() {
                _statusMessage = 'Consent updated!';
                _loadStoredConsent(); // Reload to show new consent
              });
              
              // Here you would typically enable/disable your tracking SDKs
              print('📊 Consent changed: $consentByCategory');
              
              // Example: Enable analytics if allowed
              if (consentByCategory[2] == true) { // Assuming category 2 is analytics
                print('✅ Analytics enabled');
                // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
              }
            },
            
            // Callback when user accepts all
            onAcceptAll: () {
              print('✅ User accepted all cookies');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All cookies accepted!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            
            // Callback when user rejects all
            onRejectAll: () {
              print('❌ User rejected all non-necessary cookies');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Only necessary cookies enabled'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            
            // Callback for errors
            onError: (error) {
              print('⚠️ Cookie banner error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Banner error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard(String title, bool isAllowed, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: isAllowed ? Colors.green : Colors.grey,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: Icon(
          isAllowed ? Icons.check_circle : Icons.cancel,
          color: isAllowed ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
