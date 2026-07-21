class LoanAccountMaster {
  final String orgCode;
  final String loanAccountNo;
  final String? queueId;
  final String clientId;
  final String? groupCode;
  final String productCode;
  final String currencyCode;
  final double disbursedAmount;
  final DateTime disbursementDate;
  final DateTime maturityDate;
  final String loanStatus;
  final double outstandingPrincipal;
  final double outstandingInterest;
  final String? currentDelinquencyCode;
  final DateTime? classificationEffectiveDate;
  final String? collateralRef;
  
  final String eUser;
  final DateTime eDate;
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;

  LoanAccountMaster({
    required this.orgCode,
    required this.loanAccountNo,
    this.queueId,
    required this.clientId,
    this.groupCode,
    required this.productCode,
    this.currencyCode = 'INR',
    required this.disbursedAmount,
    required this.disbursementDate,
    required this.maturityDate,
    required this.loanStatus,
    required this.outstandingPrincipal,
    required this.outstandingInterest,
    this.currentDelinquencyCode,
    this.classificationEffectiveDate,
    this.collateralRef,
    required this.eUser,
    required this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });
}
