class Branch {
  final int orgCode;
  final int branchCode;
  final String branchName;
  final String? openDate;
  final String? address;
  final String? country;
  final String? divisionName;
  final String? pincode;
  final String? telephone;
  final String? email;
  final bool? status;
  final bool? headBranch;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? addressLine4;
  final String? addressLine5;
  int? pgmId;
  String? userName;
  String? cuser, cdate, euser, edate, auser, adate;

  Branch({
    required this.orgCode,
    required this.branchCode,
    required this.branchName,
    this.openDate,
    this.address,
    this.country,
    this.divisionName,
    this.pincode,
    this.telephone,
    this.email,
    this.status,
    this.headBranch,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.addressLine4,
    this.addressLine5,
    this.pgmId,
    this.userName,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      final text = value.toString().toLowerCase();
      if (text == 'true' || text == '1') return true;
      if (text == 'false' || text == '0') return false;
      return null;
    }

    String? parseString(dynamic value) => value?.toString();

    return Branch(
      orgCode: parseInt(json['orgCode']),
      branchCode: parseInt(json['brncd'] ?? json['branchCode']),
      branchName: parseString(json['brnname'] ?? json['branchName']) ?? '',
      openDate: parseString(json['openDate']),
      address: parseString(json['address']),
      country: parseString(json['country']),
      divisionName: parseString(json['divisionName']),
      pincode: (json['pincode'] ?? json['pinCode'])?.toString(),
      telephone: parseString(json['telephone']),
      email: parseString(json['email']),
      status: parseBool(json['status']),
      headBranch: parseBool(json['headbrn'] ?? json['headBranch']),
      addressLine1: parseString(json['addrline1'] ?? json['addressLine1']),
      addressLine2: parseString(json['addrline2'] ?? json['addressLine2']),
      addressLine3: parseString(json['addrline3'] ?? json['addressLine3']),
      addressLine4: parseString(json['addrline4'] ?? json['addressLine4']),
      addressLine5: parseString(json['addrline5'] ?? json['addressLine5']),
      userName: parseString(json['userName']),
      cuser: parseString(json['cuser']),
      cdate: parseString(json['cdate']),
      euser: parseString(json['euser']),
      edate: parseString(json['edate']),
      auser: parseString(json['auser']),
      adate: parseString(json['adate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgCode': orgCode,
      'brncd': branchCode,
      'brnname': branchName,
      'openDate': openDate,
      'address': address,
      'country': country,
      'divisionName': divisionName,
      'pincode': pincode,
      'telephone': telephone,
      'email': email,
      'status': status,
      'headbrn': headBranch,
      'addrline1': addressLine1,
      'addrline2': addressLine2,
      'addrline3': addressLine3,
      'addrline4': addressLine4,
      'addrline5': addressLine5,
      if (pgmId != null) 'pgmId': pgmId,
      'userName': userName,
      'cuser': cuser,
      'cdate': cdate,
      'euser': euser,
      'edate': edate,
      'auser': auser,
      'adate': adate,
    };
  }
}
