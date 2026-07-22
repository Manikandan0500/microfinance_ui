class DisbursalQueue {
  String orgCode;
  String queueId;
  String clientType;   // 'I' = Individual, 'C' = Corporate, 'G' = Group
  String sourceSystem;
  String? sourceRefNo;
  String clientId;
  String? groupCode;
  String productCode;
  double approvedAmount;
  int approvedTenureMonths;
  double approvedInterestRate;
  DateTime queuedDate;
  String? assignedToUserId;
  String disbursementStatus;

  DisbursalQueue({
    required this.orgCode,
    required this.queueId,
    this.clientType = 'I',
    required this.sourceSystem,
    this.sourceRefNo,
    required this.clientId,
    this.groupCode,
    required this.productCode,
    required this.approvedAmount,
    required this.approvedTenureMonths,
    required this.approvedInterestRate,
    required this.queuedDate,
    this.assignedToUserId,
    required this.disbursementStatus,
  });

  DisbursalQueue copyWith({
    String? orgCode,
    String? queueId,
    String? clientType,
    String? sourceSystem,
    String? sourceRefNo,
    String? clientId,
    String? groupCode,
    double? approvedAmount,
    String? productCode,
    int? approvedTenureMonths,
    double? approvedInterestRate,
    DateTime? queuedDate,
    String? assignedToUserId,
    String? disbursementStatus,
  }) {
    return DisbursalQueue(
      orgCode: orgCode ?? this.orgCode,
      queueId: queueId ?? this.queueId,
      clientType: clientType ?? this.clientType,
      sourceSystem: sourceSystem ?? this.sourceSystem,
      sourceRefNo: sourceRefNo ?? this.sourceRefNo,
      clientId: clientId ?? this.clientId,
      groupCode: groupCode ?? this.groupCode,
      productCode: productCode ?? this.productCode,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      approvedTenureMonths: approvedTenureMonths ?? this.approvedTenureMonths,
      approvedInterestRate: approvedInterestRate ?? this.approvedInterestRate,
      queuedDate: queuedDate ?? this.queuedDate,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      disbursementStatus: disbursementStatus ?? this.disbursementStatus,
    );
  }
}
