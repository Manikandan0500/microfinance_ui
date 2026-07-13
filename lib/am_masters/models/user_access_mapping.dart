class UserAccessMapping {
  final int? accesscd; // Primary key, nullable for new records
  final int orgcode;
  final String userscd;
  final int syscode;
  final int prodcode;
  final bool status;
  final String? euser; // Edited by
  final DateTime? edate; // Edited date
  final String? auser; // Approved by
  final DateTime? adate; // Approved date
  final String? cuser; // Created by
  final DateTime? cdate; // Created date
  String userName; // Not from JSON, for display purposes

  UserAccessMapping({
    this.accesscd,
    required this.orgcode,
    required this.userscd,
    required this.syscode,
    required this.prodcode,
    required this.status,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.cuser,
    this.cdate,
    this.userName = '', // Default to empty string
  });

  factory UserAccessMapping.fromJson(Map<String, dynamic> json) {
    return UserAccessMapping(
      accesscd: json['accesscd'] as int?,
      orgcode: json['orgcode'] as int,
      userscd: json['userscd'] as String,
      syscode: json['syscode'] != null ? json['syscode'] as int : 0,
      prodcode: json['prodcode'] as int,
      status: json['status'] as bool,
      euser: json['euser'] as String?,
      edate: json['edate'] != null ? DateTime.parse(json['edate']) : null,
      auser: json['auser'] as String?,
      adate: json['adate'] != null ? DateTime.parse(json['adate']) : null,
      cuser: json['cuser'] as String?,
      cdate: json['cdate'] != null ? DateTime.parse(json['cdate']) : null,
      userName: json['userName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accesscd != null) 'accesscd': accesscd,
      'orgcode': orgcode,
      'userscd': userscd,
      'syscode': syscode,
      'prodcode': prodcode,
      'status': status,
      'euser': euser,
      'edate': edate?.toIso8601String(),
      'auser': auser,
      'adate': adate?.toIso8601String(),
      'cuser': cuser,
      'cdate': cdate?.toIso8601String(),
      'userName': userName,
    };
  }
}