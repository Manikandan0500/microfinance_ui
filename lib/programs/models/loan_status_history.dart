class LoanStatusHistory {
  final String orgCode;
  final String loanAccountNo;
  final int statusSeqNo;
  final String? statusFrom;
  final String statusTo;
  final DateTime changedDate;
  final String changedBy;
  final String? remarks;
  final String eUser;
  final DateTime eDate;
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;

  LoanStatusHistory({
    required this.orgCode,
    required this.loanAccountNo,
    required this.statusSeqNo,
    this.statusFrom,
    required this.statusTo,
    required this.changedDate,
    required this.changedBy,
    this.remarks,
    required this.eUser,
    required this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });
}
