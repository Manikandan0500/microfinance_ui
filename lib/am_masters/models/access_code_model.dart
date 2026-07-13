class AccessCode {
  final int? id;
  final int orgCode;
  final String accessName;
  final String? accessType;
  final String? accessSubtype;
  final bool viewAccess;
  final bool authAccess;
  final bool makerAccess;
  final bool adminAccess;
  final bool sysAdminAccess;
  final bool active;
  final List<int>? hmenuCds;
  final String? euser;
  final DateTime? edate;
  final String? auser;
  final DateTime? adate;
  final String? cuser;
  final DateTime? cdate;

  AccessCode({
    this.id,
    required this.orgCode,
    required this.accessName,
    this.accessType,
    this.accessSubtype,
    required this.viewAccess,
    required this.authAccess,
    required this.makerAccess,
    required this.adminAccess,
    required this.sysAdminAccess,
    this.active = true,
    this.hmenuCds,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.cuser,
    this.cdate,
  });

  factory AccessCode.fromJson(Map<String, dynamic> json) {
    return AccessCode(
      id: json['accesscd'] as int?,
      orgCode: json['orgcode'] as int,
      accessName: json['accessname'] as String,
      accessType: json['accesstype'] as String?,
      accessSubtype: json['accesssubtype'] as String?,
      viewAccess: json['viewaccess'] as bool? ?? false,
      authAccess: json['authaccess'] as bool? ?? false,
      makerAccess: json['makeraccess'] as bool? ?? false,
      adminAccess: json['adminaccess'] as bool? ?? false,
      sysAdminAccess: json['sysadminaccess'] as bool? ?? false,
      active: true, // Assuming active based on existence
      hmenuCds: json['hmenuCds'] != null ? List<int>.from(json['hmenuCds']) : null,
      euser: json['euser'] as String?,
      edate: json['edate'] != null ? DateTime.parse(json['edate']) : null,
      auser: json['auser'] as String?,
      adate: json['adate'] != null ? DateTime.parse(json['adate']) : null,
      cuser: json['cuser'] as String?,
      cdate: json['cdate'] != null ? DateTime.parse(json['cdate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'accesscd': id,
      'orgcode': orgCode,
      'accessname': accessName,
      if (accessType != null) 'accesstype': accessType,
      if (accessSubtype != null) 'accesssubtype': accessSubtype,
      'viewaccess': viewAccess,
      'authaccess': authAccess,
      'makeraccess': makerAccess,
      'adminaccess': adminAccess,
      'sysadminaccess': sysAdminAccess,
      if (hmenuCds != null && hmenuCds!.isNotEmpty) 'hmenuCds': hmenuCds,
      if (euser != null) 'euser': euser,
      if (edate != null) 'edate': edate!.toIso8601String(),
      if (auser != null) 'auser': auser,
      if (adate != null) 'adate': adate!.toIso8601String(),
      if (cuser != null) 'cuser': cuser,
      if (cdate != null) 'cdate': cdate!.toIso8601String(),
    };
  }

  AccessCode copyWith({
    int? id,
    int? orgCode,
    String? accessName,
    String? accessType,
    String? accessSubtype,
    bool? viewAccess,
    bool? authAccess,
    bool? makerAccess,
    bool? adminAccess,
    bool? sysAdminAccess,
    bool? active,
    List<int>? hmenuCds,
    String? euser,
    DateTime? edate,
    String? auser,
    DateTime? adate,
    String? cuser,
    DateTime? cdate,
  }) {
    return AccessCode(
      id: id ?? this.id,
      orgCode: orgCode ?? this.orgCode,
      accessName: accessName ?? this.accessName,
      accessType: accessType ?? this.accessType,
      accessSubtype: accessSubtype ?? this.accessSubtype,
      viewAccess: viewAccess ?? this.viewAccess,
      authAccess: authAccess ?? this.authAccess,
      makerAccess: makerAccess ?? this.makerAccess,
      adminAccess: adminAccess ?? this.adminAccess,
      sysAdminAccess: sysAdminAccess ?? this.sysAdminAccess,
      active: active ?? this.active,
      hmenuCds: hmenuCds ?? this.hmenuCds,
      euser: euser ?? this.euser,
      edate: edate ?? this.edate,
      auser: auser ?? this.auser,
      adate: adate ?? this.adate,
      cuser: cuser ?? this.cuser,
      cdate: cdate ?? this.cdate,
    );
  }
}