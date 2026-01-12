/// Cookie Banner SDK for Flutter
///
/// A GDPR/CCPA-compliant cookie consent management SDK for Flutter apps.
/// Provides dynamic configuration, consent persistence, and integration hooks.
library cookie_banner_sdk;

// Main widget
export 'cookie_banner.dart';

// Public models that host apps might need
export 'src/models/banner_design.dart';
export 'src/models/consent_snapshot.dart';
export 'src/models/user_data_properties.dart';

// Public services for advanced usage
export 'src/services/consent_storage.dart';

// Public utilities for consent evaluation
export 'src/utils/consent_evaluator.dart';
