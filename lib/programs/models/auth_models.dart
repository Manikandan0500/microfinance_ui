// Auth Configuration model — maps to auth101 table
class Auth101Config {
  final String id; // programId
  final String name;
  final bool approvalReq;
  final bool preApproveProc;
  final bool postApproveProc;
  final bool isTran;
  final int levels;
  final int orgCode;

  const Auth101Config({
    required this.id,
    required this.name,
    required this.approvalReq,
    this.preApproveProc = false,
    this.postApproveProc = false,
    required this.isTran,
    required this.levels,
    this.orgCode = 101,
  });

  factory Auth101Config.fromJson(Map<String, dynamic> json) {
    final idField = json['id'] as Map<String, dynamic>?;
    return Auth101Config(
      id: (idField?['programId'] ?? json['programId'] ?? '').toString(),
      name: (json['programId'] ?? '').toString(),
      approvalReq: (json['approvalReq'] ?? 0) == 1,
      preApproveProc: (json['preApproveProc'] ?? 0) == 1,
      postApproveProc: (json['postApproveProc'] ?? 0) == 1,
      isTran: (json['isTranPgm'] ?? 0) == 1,
      levels: 1,
      orgCode: (idField?['orgCode'] ?? json['orgCode'] ?? 101) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': {'programId': id, 'orgCode': orgCode},
      'approvalReq': approvalReq ? 1 : 0,
      'preApproveProc': preApproveProc ? 1 : 0,
      'postApproveProc': postApproveProc ? 1 : 0,
      'isTranPgm': isTran ? 1 : 0,
      'orgCode': orgCode,
    };
  }
}

// A single table's data block within an auth record
class AuthDataBlock {
  final int recSl;
  final String tableName;
  final Map<String, dynamic> data;

  AuthDataBlock({
    required this.recSl,
    required this.tableName,
    required this.data,
  });

  factory AuthDataBlock.fromJson(Map<String, dynamic> json) {
    return AuthDataBlock(
      recSl: (json['recSl'] ?? 0) as int,
      tableName: (json['tableName'] ?? '').toString(),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }
}

// Pending authorization record from the auth queue
class AuthRecord {
  final String orgCode;
  final String effDate;
  final String programId;
  final String primaryKey;
  final String authSl;
  final String displayRemarks;
  final String eUser;
  final String eDate;
  final List<AuthDataBlock> dataBlocks;

  AuthRecord({
    required this.orgCode,
    required this.effDate,
    required this.programId,
    required this.primaryKey,
    required this.authSl,
    required this.displayRemarks,
    required this.eUser,
    required this.eDate,
    this.dataBlocks = const [],
  });

  factory AuthRecord.fromJson(Map<String, dynamic> json) {
    final dataList = (json['dataBlocks'] as List<dynamic>?) ?? [];
    return AuthRecord(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? '').toString(),
      effDate: (json['edate'] ?? json['effDate'] ?? '').toString(),
      programId: (json['programid'] ?? json['programId'] ?? '').toString(),
      primaryKey: (json['primaryKey'] ?? json['authSl'] ?? json['authsl'] ?? '').toString(),
      authSl: (json['authSl'] ?? json['authsl'] ?? '').toString(),
      displayRemarks: (json['display_remarks'] ?? json['displayRemarks'] ?? json['remarks'] ?? '').toString(),
      eUser: (json['euser'] ?? json['eUser'] ?? '').toString(),
      eDate: (json['edate'] ?? json['eDate'] ?? '').toString(),
      dataBlocks: dataList.map((d) => AuthDataBlock.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}
