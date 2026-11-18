class Scammer {
  final String id;
  final String? phoneNumber;
  final String? upiId;
  final String? name;
  final int reportedCount;
  final String? createdAt;

  Scammer({
    required this.id,
    this.phoneNumber,
    this.upiId,
    this.name,
    required this.reportedCount,
    this.createdAt,
  });

  factory Scammer.fromJson(Map<String, dynamic> json) {
    return Scammer(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      upiId: json['upi_id']?.toString(),
      name: json['name']?.toString(),
      reportedCount: json['reported_count'] as int? ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'upi_id': upiId,
        'name': name,
        'reported_count': reportedCount,
        'created_at': createdAt,
      };

  String get displayIdentifier {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) return phoneNumber!;
    if (upiId != null && upiId!.isNotEmpty) return upiId!;
    return 'Unknown';
  }
}
