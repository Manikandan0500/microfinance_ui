class Module {
  final int moduleId;
  final String moduleName;
  final bool subModule;
  final bool status;
  String? userName;
  String? cuser, cdate, euser, edate, auser, adate;

  Module({
    required this.moduleId,
    required this.moduleName,
    required this.subModule,
    required this.status,
    this.userName,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      moduleId: json['moduleId'] as int,
      moduleName: json['moduleName'] as String,
      subModule: json['subModule'] as bool,
      status: json['status'] as bool,
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
      'moduleId': moduleId,
      'moduleName': moduleName,
      'subModule': subModule,
      'status': status,
      'userName': userName,
      'cuser': cuser,
      'cdate': cdate,
      'euser': euser,
      'edate': edate,
      'auser': auser,
      'adate': adate,
    };
  }

  Module copyWith({
    int? moduleId,
    String? moduleName,
    bool? subModule,
    bool? status,
    String? userName,
    String? cuser,
    String? cdate,
    String? euser,
    String? edate,
    String? auser,
    String? adate,
  }) {
    return Module(
      moduleId: moduleId ?? this.moduleId,
      moduleName: moduleName ?? this.moduleName,
      subModule: subModule ?? this.subModule,
      status: status ?? this.status,
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