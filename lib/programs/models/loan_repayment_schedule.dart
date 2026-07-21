class LoanRepaymentSchedule {
  final String orgCode;
  final String loanAccountNo;
  final int installmentNo;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double totalDue;
  final double? principalPaid;
  final double? interestPaid;
  final String installmentStatus;
  final String eUser;
  final DateTime eDate;
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;

  LoanRepaymentSchedule({
    required this.orgCode,
    required this.loanAccountNo,
    required this.installmentNo,
    required this.dueDate,
    required this.principalDue,
    required this.interestDue,
    required this.totalDue,
    this.principalPaid,
    this.interestPaid,
    required this.installmentStatus,
    required this.eUser,
    required this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });
}
