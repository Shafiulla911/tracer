class TrackLog {
  final String? ipAddress;
  final String? city;
  final String? region;
  final String? country;
  final String? deviceType;
  final String? browser;
  final String? os;
  final String? clickedAt;
  final double? latitude;
  final double? longitude;

  TrackLog({
    this.ipAddress,
    this.city,
    this.region,
    this.country,
    this.deviceType,
    this.browser,
    this.os,
    this.clickedAt,
    this.latitude,
    this.longitude,
  });

  factory TrackLog.fromJson(Map<String, dynamic> json) {
    return TrackLog(
      ipAddress: json['ip_address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      deviceType: json['device_type']?.toString(),
      browser: json['browser']?.toString(),
      os: json['os']?.toString(),
      clickedAt: json['clicked_at']?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  String get locationDisplay {
    final parts = [city, region, country].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }
}
