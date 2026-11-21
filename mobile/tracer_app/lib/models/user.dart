class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String badge;
  final String role;
  final String? avatarUrl;
  final DateTime? createdAt;
  final int reportsCount;
  final int trapsCount;
  final int hitsCount;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.badge = 'Field Investigator',
    this.role = 'Agent',
    this.avatarUrl,
    this.createdAt,
    this.reportsCount = 0,
    this.trapsCount = 0,
    this.hitsCount = 0,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) {
      return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'AG';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'Agent',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      badge: json['badge']?.toString() ?? 'Field Investigator • Level 1',
      role: json['role']?.toString() ?? 'Agent',
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      reportsCount: json['reports_count'] is int ? json['reports_count'] as int : (int.tryParse(json['reports_count']?.toString() ?? '0') ?? 0),
      trapsCount: json['traps_count'] is int ? json['traps_count'] as int : (int.tryParse(json['traps_count']?.toString() ?? '0') ?? 0),
      hitsCount: json['hits_count'] is int ? json['hits_count'] as int : (int.tryParse(json['hits_count']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'badge': badge,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'reports_count': reportsCount,
      'traps_count': trapsCount,
      'hits_count': hitsCount,
    };
  }

  User copyWith({
    String? fullName,
    String? phone,
    String? badge,
    int? reportsCount,
    int? trapsCount,
    int? hitsCount,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      badge: badge ?? this.badge,
      role: role,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      reportsCount: reportsCount ?? this.reportsCount,
      trapsCount: trapsCount ?? this.trapsCount,
      hitsCount: hitsCount ?? this.hitsCount,
    );
  }
}
