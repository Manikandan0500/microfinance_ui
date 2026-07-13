class Organization {
  final int orgcode;
  final String name;
  final String? opendate;
  final String? logo;
  final String? country;
  final String? divisionname;
  final String? pincode;
  final String? addrline1;
  final String? addrline2;
  final String? addrline3;
  final String? addrline4;
  final String? addrline5;
  final String? telephone;
  final String email;
  final int? status;
  final int? indiv;
  final String? euser;
  final String? edate;
  final String? auser;
  final String? adate;
  final String? cuser;
  final String? cdate;
  final String? userName;

  Organization({
    required this.orgcode,
    required this.name,
    this.opendate,
    this.logo,
    this.country,
    this.divisionname,
    this.pincode,
    this.addrline1,
    this.addrline2,
    this.addrline3,
    this.addrline4,
    this.addrline5,
    this.telephone,
    required this.email,
    this.status,
    this.indiv,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.cuser,
    this.cdate,
    this.userName,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      orgcode: json['orgcode'] as int,
      name: json['name'] as String,
      opendate: json['opendate'] as String?,
      logo: json['logo'] as String?,
      country: json['country'] as String?,
      divisionname: json['divisionname'] as String?,
      pincode: json['pincode'] as String?,
      addrline1: json['addrline1'] as String?,
      addrline2: json['addrline2'] as String?,
      addrline3: json['addrline3'] as String?,
      addrline4: json['addrline4'] as String?,
      addrline5: json['addrline5'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String,
      status: json['status'] as int?,
      indiv: json['indiv'] as int?,
      euser: json['euser'] as String?,
      edate: json['edate'] as String?,
      auser: json['auser'] as String?,
      adate: json['adate'] as String?,
      cuser: json['cuser'] as String?,
      cdate: json['cdate'] as String?,
      userName: json['userName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgcode': orgcode,
      'name': name,
      'opendate': opendate,
      'logo': logo,
      'country': country,
      'divisionname': divisionname,
      'pincode': pincode,
      'addrline1': addrline1,
      'addrline2': addrline2,
      'addrline3': addrline3,
      'addrline4': addrline4,
      'addrline5': addrline5,
      'telephone': telephone,
      'email': email,
      'status': status,
      'indiv': indiv,
      'euser': euser,
      'edate': edate,
      'auser': auser,
      'adate': adate,
      'cuser': cuser,
      'cdate': cdate,
      'userName': userName,
    };
  }
}
