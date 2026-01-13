import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// API client for cookie banner backend communication.
///
/// Handles all HTTP requests to fetch banner configuration, update consent,
/// send metrics, and fetch translations. Mirrors the React implementation's
/// API integration.
class CookieBannerApiClient {
  final String baseUrl;
  final http.Client? httpClient;

  /// CDN base URL for pre-generated banner configurations
  static const String cdnBaseUrl =
      'https://d1axzsitviir9s.cloudfront.net/banner';

  CookieBannerApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Fetch banner data from CDN (primary method).
  ///
  /// GET https://d1axzsitviir9s.cloudfront.net/banner/{domainURL}_{domainId}.json
  ///
  /// Returns array of UserDataProperties (one per language).
  Future<List<UserDataProperties>> fetchBannerDataFromCdn({
    required String domainUrl,
    required int domainId,
  }) async {
    try {
      // Sanitize domainUrl: remove all slashes to match React implementation
      final sanitizedDomain = domainUrl.replaceAll('/', '').replaceAll('\\', '');
      final fileName = '${sanitizedDomain}_$domainId.json';
      final url = Uri.parse('$cdnBaseUrl/$fileName');
      print("line 35 $url");

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract data array from result.data structure
        final result = responseJson['result'] as Map<String, dynamic>?;
        final List<dynamic> jsonList = (result?['data'] ?? responseJson) as List;
        
        return jsonList
            .map((json) =>
                UserDataProperties.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw CookieBannerApiException(
          'CDN fetch failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('CDN fetch error: $e', null);
    }
  }

  /// Fetch banner data from API (fallback method).
  ///
  /// GET {baseURL}/ucm/v2/banner/display?domain_id={id}&subject_identity={uuid}&country_name={country}
  Future<UserDataProperties> fetchBannerDataFallback({
    required int domainId,
    required String subjectIdentity,
    required String countryName,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ucm/v2/banner/display').replace(
        queryParameters: {
          'domain_id': domainId.toString(),
          'subject_identity': subjectIdentity,
          'country_name': countryName,
        },
      );

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UserDataProperties.fromJson(json);
      } else {
        throw CookieBannerApiException(
          'Fallback API fetch failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('Fallback API error: $e', null);
    }
  }

  /// Fetch available languages for a domain.
  ///
  /// GET {baseURL}/ucm/v2/domain/languages?domain_id={id}
  Future<List<Language>> fetchLanguages({
    required int domainId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ucm/v2/domain/languages').replace(
        queryParameters: {
          'domain_id': domainId.toString(),
        },
      );
      print("from line 108 $url");

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        return jsonList
            .map((json) => Language.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw CookieBannerApiException(
          'Languages fetch failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('Languages fetch error: $e', null);
    }
  }

  /// Update consent choices on the backend.
  ///
  /// PUT {baseURL}/ucm/banner/record-status-update
  Future<void> updateConsent({
    required ConsentSnapshot snapshot,
    required String geolocation,
    required String continent,
    required String country,
    required String source,
    required List<CookieConsent> cookieCategoryConsent,
    DeviceInfoData? deviceInfo,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ucm/banner/record-status-update');

      final body = {
        'domain_id': snapshot.domainId,
        'subject_identity': snapshot.subjectIdentity,
        'geolocation': geolocation,
        'continent': continent,
        'country': country,
        'source': source,
        'cookie_category_consent':
            cookieCategoryConsent.map((c) => c.toJson()).toList(),
        if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
      };

      final response = await httpClient!.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CookieBannerApiException(
          'Consent update failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('Consent update error: $e', null);
    }
  }

  /// Send performance metrics to backend.
  ///
  /// POST {baseURL}/ucm/v2/banner/load-time
  Future<void> sendLoadTimeMetrics({
    required int domainId,
    required String subjectIdentity,
    required String domainUrl,
    int? cdnResponseTime,
    int? apiResponseTime,
    int? totalLoadTime,
    int? bannerDisplayTime,
    int? userReactionTime,
    String loadMethod = 'cdn',
    DeviceInfoData? deviceInfo,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/ucm/v2/banner/load-time');

      final body = {
        'domain_id': domainId,
        'subject_identity': subjectIdentity,
        'domain_url': domainUrl,
        if (cdnResponseTime != null) 'cdn_response_time': cdnResponseTime,
        if (apiResponseTime != null) 'api_response_time': apiResponseTime,
        if (totalLoadTime != null) 'total_load_time': totalLoadTime,
        if (bannerDisplayTime != null) 'banner_display_time': bannerDisplayTime,
        if (userReactionTime != null) 'user_reaction_time': userReactionTime,
        'load_method': loadMethod,
        if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
      };

      final response = await httpClient!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Don't throw - metrics are non-critical
        print('Warning: Load time metrics failed: ${response.statusCode}');
      }
    } catch (e) {
      // Don't throw - metrics are non-critical
      print('Warning: Load time metrics error: $e');
    }
  }

  /// Fetch IP geolocation information.
  ///
  /// GET {baseURL}/backend/api/v3/gt/ip-info/{ip}
  Future<GeoLocationInfo> fetchIpInfo({
    required String ip,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/backend/api/v3/gt/ip-info/$ip');

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = json['result'] as Map<String, dynamic>?;

        if (result != null) {
          return GeoLocationInfo.fromJson(result);
        } else {
          throw CookieBannerApiException('Invalid IP info response', null);
        }
      } else {
        throw CookieBannerApiException(
          'IP info fetch failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('IP info fetch error: $e', null);
    }
  }

  /// Fetch user's public IP address.
  ///
  /// GET https://api.ipify.org?format=json
  Future<String> fetchPublicIp() async {
    try {
      final url = Uri.parse('https://api.ipify.org?format=json');

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['ip'] as String? ?? '';
      } else {
        throw CookieBannerApiException(
          'IP fetch failed',
          response.statusCode,
        );
      }
    } catch (e) {
      throw CookieBannerApiException('IP fetch error: $e', null);
    }
  }

  void dispose() {
    httpClient?.close();
  }
}

/// Geolocation information from IP lookup.
class GeoLocationInfo {
  final String countryCode;
  final String country;
  final String continent;

  const GeoLocationInfo({
    required this.countryCode,
    required this.country,
    required this.continent,
  });

  factory GeoLocationInfo.fromJson(Map<String, dynamic> json) {
    return GeoLocationInfo(
      countryCode: json['country_code'] as String? ?? 'US',
      country: json['country'] as String? ?? 'United States',
      continent: json['continent'] as String? ?? 'North America',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'country': country,
      'continent': continent,
    };
  }
}

/// Exception thrown by API client operations.
class CookieBannerApiException implements Exception {
  final String message;
  final int? statusCode;

  CookieBannerApiException(this.message, this.statusCode);

  @override
  String toString() {
    if (statusCode != null) {
      return 'CookieBannerApiException: $message (Status: $statusCode)';
    }
    return 'CookieBannerApiException: $message';
  }
}
