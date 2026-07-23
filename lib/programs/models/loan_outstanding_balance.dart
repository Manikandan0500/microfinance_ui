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

  factory LoanOutstandingBalance.fromJson(Map<String, dynamic> json) {
    return LoanOutstandingBalance(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? '101').toString(),
      loanAccountNo: (json['loan_account_no'] ?? json['loanAccountNo'] ?? '').toString(),
      asOnDate: json['as_on_date'] != null 
          ? DateTime.parse(json['as_on_date'].toString()) 
          : (json['asOnDate'] != null ? DateTime.parse(json['asOnDate'].toString()) : DateTime.now()),
      principalOutstanding: (json['principal_outstanding'] ?? json['principalOutstanding'] as num?)?.toDouble() ?? 0.0,
      interestOutstanding: (json['interest_outstanding'] ?? json['interestOutstanding'] as num?)?.toDouble() ?? 0.0,
      penaltyOutstanding: (json['penalty_outstanding'] ?? json['penaltyOutstanding'] as num?)?.toDouble() ?? 0.0,
      totalOutstanding: (json['total_outstanding'] ?? json['totalOutstanding'] as num?)?.toDouble() ?? 0.0,
      eUser: (json['euser'] ?? json['eUser'] ?? 'SYS').toString(),
      eDate: json['edate'] != null 
          ? DateTime.parse(json['edate'].toString()) 
          : (json['eDate'] != null ? DateTime.parse(json['eDate'].toString()) : DateTime.now()),
      aUser: json['auser']?.toString() ?? json['aUser']?.toString(),
      aDate: json['adate'] != null 
          ? DateTime.parse(json['adate'].toString()) 
          : (json['aDate'] != null ? DateTime.parse(json['aDate'].toString()) : null),
      cUser: json['cuser']?.toString() ?? json['cUser']?.toString(),
      cDate: json['cdate'] != null 
          ? DateTime.parse(json['cdate'].toString()) 
          : (json['cDate'] != null ? DateTime.parse(json['cDate'].toString()) : null),
    );
  }
}

