class LoanOutstandingBalance {
  final String orgCode;
  final String loanAccountNo;
  final DateTime asOnDate;
  final double principalOutstanding;
  final double interestOutstanding;
  final double? penaltyOutstanding;
  final double totalOutstanding;
  final String eUser;
  final DateTime eDate;
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;

  LoanOutstandingBalance({
    required this.orgCode,
    required this.loanAccountNo,
    required this.asOnDate,
    required this.principalOutstanding,
    required this.interestOutstanding,
    this.penaltyOutstanding,
    required this.totalOutstanding,
    required this.eUser,
    required this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });
}
