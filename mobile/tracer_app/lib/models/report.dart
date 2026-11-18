class Report {
  final String id;
  final String scammerId;
  final String? phoneNumber;
  final String? upiId;
  final String? scammerName;
  final String? description;
  final String? victimName;
  final double? amountLost;
  final String? paymentMethod;
  final String? createdAt;

  Report({
    required this.id,
    required this.scammerId,
    this.phoneNumber,
    this.upiId,
    this.scammerName,
    this.description,
    this.victimName,
    this.amountLost,
    this.paymentMethod,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      scammerId: json['scammer_id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      upiId: json['upi_id']?.toString(),
      scammerName: json['name']?.toString(),
      description: json['description']?.toString(),
      victimName: json['victim_name']?.toString(),
      amountLost: json['amount_lost'] != null
          ? double.tryParse(json['amount_lost'].toString())
          : null,
      paymentMethod: json['payment_method']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scammer_id': scammerId,
        'phone_number': phoneNumber,
        'upi_id': upiId,
        'name': scammerName,
        'description': description,
        'victim_name': victimName,
        'amount_lost': amountLost,
        'payment_method': paymentMethod,
        'created_at': createdAt,
      };
}
