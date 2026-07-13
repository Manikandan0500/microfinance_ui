// ── Date formatter helper ──────────────────────────────────────────────────────
String _formatDateWithPaddedDay(String? dateString) {
  if (dateString == null || dateString.isEmpty) return dateString ?? '';
  
  // Format: YYYY-MMM-D or YYYY-MMM-DD (e.g., "2026-Jan-5" -> "2026-Jan-05")
  // Also handles: "2026-Jan-05" (already padded)
  final regex = RegExp(r'^(\d{4})-([A-Za-z]{3})-(\d{1,2})$');
  final match = regex.firstMatch(dateString);
  
  if (match != null) {
    final year = match.group(1);
    final month = match.group(2);
    final day = match.group(3);
    return '$year-$month-${day!.padLeft(2, '0')}';
  }
  
  // Format: DD-MMM-YYYY or D-MMM-YYYY (e.g., "5-Jan-2026" -> "05-Jan-2026")
  final regex2 = RegExp(r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})$');
  final match2 = regex2.firstMatch(dateString);
  
  if (match2 != null) {
    final day = match2.group(1);
    final month = match2.group(2);
    final year = match2.group(3);
    return '${day!.padLeft(2, '0')}-$month-$year';
  }
  
  // Format: MM/DD/YYYY or M/D/YYYY (e.g., "1/5/2026" -> "01/05/2026")
  final regex3 = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
  final match3 = regex3.firstMatch(dateString);
  
  if (match3 != null) {
    final month = match3.group(1);
    final day = match3.group(2);
    final year = match3.group(3);
    return '${month!.padLeft(2, '0')}/${day!.padLeft(2, '0')}/$year';
  }
  
  // Return original if no match
  return dateString;
}

class UserAccount {
  final int orgCode;
  final String userCode;
  final String? title;
  final String? mName;
  final String? gender;
  final String? regDate;
  final int? status;
  final int? branchCode;
  final String? picture;
  final String? dob;
  final String? country;
  final String? callCode;

  final String? fName;
  final String? lName;
  final String? emailId;
  final String? mobile;
  int? pgmId;
  String userName; // Not from JSON, for display purposes
  final String? roleType;
  
  final String? cuser;
  final String? cdate;
  final String? euser;
  final String? edate;
  final String? auser;
  final String? adate;

  UserAccount({
    required this.orgCode,
    required this.userCode,
    this.title,
    this.fName,
    this.mName,
    this.lName,
    this.emailId,
    this.mobile,
    this.gender,
    this.regDate,
    this.status,
    this.branchCode,
    this.picture,
    this.dob,
    this.country,
    this.callCode,
    this.pgmId,
    this.userName = '', // Default to empty string
    this.roleType,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });

  String get statusLabel {
    switch (status) {
      case 1:
        return '1 - Active';
      case 0:
        return '0 - Inactive';
      case 2:
        return '2 - Suspended';
      case 3:
        return '3 - Locked';
      default:
        return status?.toString() ?? 'Unknown';
    }
  }

  bool get isActive => status == 1;

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return UserAccount(
      orgCode: parseInt(json['orgCode'] ?? json['orgcode']) ?? 0,
      // userCode: parseInt(json['userScd'] ?? json['userscd'] ?? json['user_code'] ?? json['id']) ?? 0,
      userCode: (
  json['userScd'] ??
  json['userscd'] ??
  json['user_code'] ??
  json['id']
)?.toString() ?? '',
      title: json['title'] as String?,
      fName: json['fName'] as String?,
      mName: json['mName'] as String?,
      lName: json['lName'] as String?,
      emailId: json['emailid'] as String?,
      mobile: json['mobile'] as String?,
      gender: json['gender'] as String?,
      regDate: json['regDate'] as String? ?? json['regdate'] as String?,
      status: parseInt(json['status']),
      branchCode: parseInt(json['brncd']),
      picture: json['picture'] as String?,
      dob: json['dob'] as String?,
      country: json['country'] as String?,
      callCode: json['callCode'] as String?,
      userName: json['userName'] as String? ?? '',
      roleType: () {
        final rt = (json['accesscd'] ?? json['accessCode'] ?? json['roleType'])?.toString();
        if (rt == '1') return 'System Administrator';
        if (rt == '2') return 'Administrator';
        if (rt == '3') return 'End user';
        return rt;
      }(),
      cuser: (json['cuser'] ?? json['CUSER'])?.toString(),
      cdate: (json['cdate'] ?? json['CDATE'])?.toString(),
      euser: (json['euser'] ?? json['EUSER'])?.toString(),
      edate: (json['edate'] ?? json['EDATE'])?.toString(),
      auser: (json['auser'] ?? json['AUSER'])?.toString(),
      adate: (json['adate'] ?? json['ADATE'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgCode': orgCode,
      'userScd': userCode,
      'title': title,
      'fName': fName,
      'mName': mName,
      'lName': lName,
      'emailid': emailId,
      'mobile': mobile,
      'gender': gender,
      'regDate': _formatDateWithPaddedDay(regDate),
      'status': status,
      'brncd': branchCode,
      'picture': picture,
      'dob': _formatDateWithPaddedDay(dob),
      'country': country,
      'callCode': (callCode != null && callCode!.isNotEmpty && !callCode!.startsWith('+')) ? '+$callCode' : callCode,
      if (pgmId != null) 'pgmId': pgmId,
      'userName': userName,
      'accesscd': () {
        if (roleType == 'System Administrator') return 1;
        if (roleType == 'Administrator') return 2;
        if (roleType == 'End user') return 3;
        return roleType != null ? int.tryParse(roleType!.toString()) : null;
      }(),
      'prodcode': 1,
    };
  }
}
