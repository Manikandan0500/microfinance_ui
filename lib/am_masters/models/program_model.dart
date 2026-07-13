class Program {
  final int pgmId;
  final String descn;
  final int moduleId;
  final int subModuleId;
  final int pgmClass;
  final bool status;
  String? userName;
  String? cuser, cdate, euser, edate, auser, adate;

  Program({
    required this.pgmId,
    required this.descn,
    required this.moduleId,
    required this.subModuleId,
    required this.pgmClass,
    required this.status,
    this.userName,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      pgmId: json['pgmId'] as int,
      descn: json['descn'] as String,
      moduleId: json['moduleId'] as int,
      subModuleId: json['subModuleId'] as int,
      pgmClass: json['pgmClass'] as int,
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
      'pgmId': pgmId,
      'descn': descn,
      'moduleId': moduleId,
      'subModuleId': subModuleId,
      'pgmClass': pgmClass,
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

  Program copyWith({
    int? pgmId,
    String? descn,
    int? moduleId,
    int? subModuleId,
    int? pgmClass,
    bool? status,
    String? userName,
    String? cuser,
    String? cdate,
    String? euser,
    String? edate,
    String? auser,
    String? adate,
  }) {
    return Program(
      pgmId: pgmId ?? this.pgmId,
      descn: descn ?? this.descn,
      moduleId: moduleId ?? this.moduleId,
      subModuleId: subModuleId ?? this.subModuleId,
      pgmClass: pgmClass ?? this.pgmClass,
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
