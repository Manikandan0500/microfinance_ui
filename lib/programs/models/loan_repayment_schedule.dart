class LoanRepaymentSchedule {
  final String loanAccountNo;
  final int installmentNo;
  final DateTime dueDate;
  final double principalDue;
  final double interestDue;
  final double totalDue;
  final double? principalPaid;
  final double? interestPaid;
  final String installmentStatus;
  final String? orgCode;
  final String? eUser;
  final DateTime? eDate;
  final String? aUser;
  final DateTime? aDate;
  final String? cUser;
  final DateTime? cDate;

  LoanRepaymentSchedule({
    required this.loanAccountNo,
    required this.installmentNo,
    required this.dueDate,
    required this.principalDue,
    required this.interestDue,
    required this.totalDue,
    this.principalPaid,
    this.interestPaid,
    required this.installmentStatus,
    this.orgCode,
    this.eUser,
    this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });

  factory LoanRepaymentSchedule.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return LoanRepaymentSchedule(
      loanAccountNo: (json['loan_account_no'] ?? json['loanAccountNo'] ?? '').toString(),
      installmentNo: (json['installment_no'] ?? json['installmentNo'] ?? 0) is int
          ? (json['installment_no'] ?? json['installmentNo'] ?? 0) as int
          : int.tryParse((json['installment_no'] ?? json['installmentNo'] ?? 0).toString()) ?? 0,
      dueDate: parseDate(json['due_date'] ?? json['dueDate']),
      principalDue: ((json['principal_due'] ?? json['principalDue'] ?? 0.0) as num).toDouble(),
      interestDue: ((json['interest_due'] ?? json['interestDue'] ?? 0.0) as num).toDouble(),
      totalDue: ((json['total_due'] ?? json['totalDue'] ?? 0.0) as num).toDouble(),
      principalPaid: json['principal_paid'] != null || json['principalPaid'] != null
          ? ((json['principal_paid'] ?? json['principalPaid']) as num).toDouble()
          : null,
      interestPaid: json['interest_paid'] != null || json['interestPaid'] != null
          ? ((json['interest_paid'] ?? json['interestPaid']) as num).toDouble()
          : null,
      installmentStatus: (json['installment_status'] ?? json['installmentStatus'] ?? 'PENDING').toString(),
      orgCode: json['orgcode']?.toString() ?? json['orgCode']?.toString(),
      eUser: json['euser']?.toString() ?? json['eUser']?.toString(),
      eDate: json['edate'] != null ? parseDate(json['edate']) : null,
      aUser: json['auser']?.toString() ?? json['aUser']?.toString(),
      aDate: json['adate'] != null ? parseDate(json['adate']) : null,
      cUser: json['cuser']?.toString() ?? json['cUser']?.toString(),
      cDate: json['cdate'] != null ? parseDate(json['cdate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan_account_no': loanAccountNo,
      'installment_no': installmentNo,
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'principal_due': principalDue,
      'interest_due': interestDue,
      'total_due': totalDue,
      'principal_paid': principalPaid,
      'interest_paid': interestPaid,
      'installment_status': installmentStatus,
    };
  }
}
