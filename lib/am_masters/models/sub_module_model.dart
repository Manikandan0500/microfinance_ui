class SubModule {
  final int subModuleId;
  final int moduleId;
  final String subModuleName;
  final bool status;
  final int? accesscd;
  String? userName;
  String? cuser, cdate, euser, edate, auser, adate;

  SubModule({
    required this.subModuleId,
    required this.moduleId,
    required this.subModuleName,
    required this.status,
    this.accesscd,
    this.userName,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });

  factory SubModule.fromJson(Map<String, dynamic> json) {
    return SubModule(
      subModuleId: json['subModuleId'] as int,
      moduleId: json['moduleId'] as int,
      subModuleName: json['subModuleName'] as String,
      status: json['status'] as bool,
      accesscd: json['accesscd'] as int?,
      userName: json['userName'] as String?,
      cuser: json['cuser'] as String?,
      cdate: json['cdate'] as String?,
      euser: json['euser'] as String?,
      edate: json['edate'] as String?,
      auser: json['auser'] as String?,
      adate: json['adate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subModuleId': subModuleId,
      'moduleId': moduleId,
      'subModuleName': subModuleName,
      'status': status,
      'accesscd': accesscd,
      'userName': userName,
      'cuser': cuser,
      'cdate': cdate,
      'euser': euser,
      'edate': edate,
      'auser': auser,
      'adate': adate,
    };
  }

  SubModule copyWith({
    int? subModuleId,
    int? moduleId,
    String? subModuleName,
    bool? status,
    int? accesscd,
    String? userName,
    String? cuser,
    String? cdate,
    String? euser,
    String? edate,
    String? auser,
    String? adate,
  }) {
    return SubModule(
      subModuleId: subModuleId ?? this.subModuleId,
      moduleId: moduleId ?? this.moduleId,
      subModuleName: subModuleName ?? this.subModuleName,
      status: status ?? this.status,
      accesscd: accesscd ?? this.accesscd,
      userName: userName ?? this.userName,
      cuser: cuser ?? this.cuser,
      cdate: cdate ?? this.cdate,
      euser: euser ?? this.euser,
      edate: edate ?? this.edate,
      auser: auser ?? this.auser,
      adate: adate ?? this.adate,
    );
  }
}