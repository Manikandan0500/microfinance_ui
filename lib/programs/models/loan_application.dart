class LoanApplication {
  final String orgCode;
  final String queueId;
  final String sourceSystem;
  final String clientId;
  final String? groupCode;
  final String productCode;
  final double approvedAmount;
  final int approvedTenureMonths;
  final double approvedInterestRate;
  final DateTime queueDate;
  final String? assignedToUserId;
  final String disbursementStatus;
  
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;
  
  final String currencyCode;

  LoanApplication({
    required this.orgCode,
    required this.queueId,
    this.sourceSystem = 'MANUAL',
    required this.clientId,
    this.groupCode,
    required this.productCode,
    required this.approvedAmount,
    required this.approvedTenureMonths,
    required this.approvedInterestRate,
    required this.queueDate,
    this.assignedToUserId,
    this.disbursementStatus = 'Pending',
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
    this.currencyCode = 'INR',
  });
}
