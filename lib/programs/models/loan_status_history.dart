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

  factory LoanStatusHistory.fromJson(Map<String, dynamic> json) {
    return LoanStatusHistory(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? '101').toString(),
      loanAccountNo: (json['loan_account_no'] ?? json['loanAccountNo'] ?? '').toString(),
      statusSeqNo: (json['status_seq_no'] ?? json['statusSeqNo'] ?? 0) as int,
      statusFrom: json['status_from']?.toString() ?? json['statusFrom']?.toString(),
      statusTo: (json['status_to'] ?? json['statusTo'] ?? '').toString(),
      changedDate: json['changed_date'] != null 
          ? DateTime.parse(json['changed_date'].toString()) 
          : (json['changedDate'] != null ? DateTime.parse(json['changedDate'].toString()) : DateTime.now()),
      changedBy: (json['changed_by'] ?? json['changedBy'] ?? '').toString(),
      remarks: json['remarks']?.toString(),
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

