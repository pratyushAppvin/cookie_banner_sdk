import 'cookie_properties.dart';

/// Represents a service (vendor) with its associated cookies.
///
/// Mirrors TypeScript `ServiceProperties` interface.
class ServiceProperties {
  final int serviceId;
  final String serviceName;
  final String serviceDescription;
  final List<CookieProperties> cookies;

  const ServiceProperties({
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.cookies,
  });

  factory ServiceProperties.fromJson(Map<String, dynamic> json) {
    return ServiceProperties(
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String? ?? '',
      serviceDescription: json['service_description'] as String? ?? '',
      cookies: (json['cookies'] as List<dynamic>?)
              ?.map((e) => CookieProperties.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'service_description': serviceDescription,
      'cookies': cookies.map((c) => c.toJson()).toList(),
    };
  }

  ServiceProperties copyWith({
    int? serviceId,
    String? serviceName,
    String? serviceDescription,
    List<CookieProperties>? cookies,
  }) {
    return ServiceProperties(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      cookies: cookies ?? this.cookies,
    );
  }
}
