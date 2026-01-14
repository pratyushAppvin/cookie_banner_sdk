import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
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
        final decoded = jsonDecode(response.body);

        // Debug: Print the response structure
        print('📦 CDN Response type: ${decoded.runtimeType}');

        List<dynamic> jsonList;

        // Handle different response formats:
        // 1. Direct array: [...]
        // 2. Nested in result.data: {"success": true, "result": {"data": [...]}}
        // 3. Direct data property: {"data": [...]}

        if (decoded is List) {
          // Format 1: Direct array
          jsonList = decoded;
          print('   Format: Direct array with ${jsonList.length} items');
        } else if (decoded is Map<String, dynamic>) {
          // Check for nested result.data structure
          final result = decoded['result'];
          if (result is Map<String, dynamic> && result['data'] is List) {
            // Format 2: Nested in result.data
            jsonList = result['data'] as List;
            print('   Format: Nested result.data with ${jsonList.length} items');
          } else if (decoded['data'] is List) {
            // Format 3: Direct data property
            jsonList = decoded['data'] as List;
            print('   Format: Direct data property with ${jsonList.length} items');
          } else {
            // Format 4: Single object (wrap in array)
            jsonList = [decoded];
            print('   Format: Single object (wrapped in array)');
          }
        } else {
          throw CookieBannerApiException(
            'Unexpected CDN response format: ${decoded.runtimeType}',
            null,
          );
        }

        // Debug: Print the actual data structure
        print('   Parsing ${jsonList.length} regulation items...');

        // Extract language objects from regulation items
        final List<Map<String, dynamic>> languageObjects = [];

        for (var i = 0; i < jsonList.length; i++) {
          final item = jsonList[i];
          if (item is Map<String, dynamic>) {
            // Check if this is a regulation object with languages array
            if (item['languages'] is List) {
              final languages = item['languages'] as List;
              print('   Regulation $i has ${languages.length} language(s)');
              for (var lang in languages) {
                if (lang is Map<String, dynamic>) {
                  languageObjects.add(lang);
                }
              }
            } else {
              // Direct language object (backward compatibility)
              languageObjects.add(item);
            }
          }
        }

        print('   Total language objects to parse: ${languageObjects.length}');

        return languageObjects
            .asMap()
            .entries
            .map((entry) {
              try {
                return UserDataProperties.fromJson(entry.value);
              } catch (e) {
                print('❌ Error parsing language object ${entry.key}: $e');
                print('   Keys: ${entry.value.keys.take(10).join(", ")}');
                rethrow;
              }
            })
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

      print('🔄 Fallback API URL: $url');

      final response = await httpClient!.get(url);

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UserDataProperties.fromJson(json);
      } else {
        print('   Response body: ${response.body}');
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
      final url = Uri.parse('$baseUrl/ucm/cp').replace(
        queryParameters: {
          'domain_id': domainId.toString(),
        },
      );
      print("from line 108 $url");

      final response = await httpClient!.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print('📦 Languages Response type: ${decoded.runtimeType}');

        List<dynamic> jsonList;

        // Handle different response formats:
        // 1. Direct array: [...]
        // 2. Nested in result.data: {"success": true, "result": {"data": [...]}}
        // 3. Direct data property: {"data": [...]}

        if (decoded is List) {
          // Format 1: Direct array
          jsonList = decoded;
          print('   Format: Direct array with ${jsonList.length} items');
        } else if (decoded is Map<String, dynamic>) {
          // Check for nested result.data structure
          final result = decoded['result'];
          if (result is Map<String, dynamic> && result['data'] is List) {
            // Format 2: Nested in result.data
            jsonList = result['data'] as List;
            print('   Format: Nested result.data with ${jsonList.length} items');
          } else if (decoded['data'] is List) {
            // Format 3: Direct data property
            jsonList = decoded['data'] as List;
            print('   Format: Direct data property with ${jsonList.length} items');
          } else {
            throw CookieBannerApiException(
              'Unexpected languages response format: ${decoded.runtimeType}',
              null,
            );
          }
        } else {
          throw CookieBannerApiException(
            'Unexpected languages response format: ${decoded.runtimeType}',
            null,
          );
        }

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

      print('🔄 Consent Update API URL: $url');

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

      print('📤 Request Body: ${jsonEncode(body)}');

      final response = await httpClient!.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CookieBannerApiException(
          'Consent update failed',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Consent update error: $e');
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
