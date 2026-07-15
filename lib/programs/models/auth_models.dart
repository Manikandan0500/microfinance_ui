import 'dart:convert';

class Auth101Config {
  final String id;
  final String name;
  final bool approvalReq;
  final bool preApproveProc;
  final String? preExecMethod; // '1': SQL, '2': API, '3': JAVA
  final String? preProcessName;
  final bool postApproveProc;
  final String? postExecMethod;
  final String? postProcessName;
  final bool isTran;
  final int levels;
  final int? orgCode;

  const Auth101Config({
    required this.id,
    required this.name,
    required this.approvalReq,
    this.preApproveProc = false,
    this.preExecMethod,
    this.preProcessName,
    this.postApproveProc = false,
    this.postExecMethod,
    this.postProcessName,
    required this.isTran,
    required this.levels,
    this.orgCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': {
        'orgCode': orgCode ?? 101,
        'programId': id,
      },
      'approvalReq': approvalReq ? 1 : 0,
      'preApproveProc': preApproveProc ? 1 : 0,
      'preExecMethod': preExecMethod,
      'preProcessName': preProcessName,
      'postApproveProc': postApproveProc ? 1 : 0,
      'postExecMethod': postExecMethod,
      'postProcessName': postProcessName,
      'isTranPgm': isTran ? 1 : 0,
    };
  }

  factory Auth101Config.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? idMap = json['id'] as Map<String, dynamic>?;
    return Auth101Config(
      id: idMap != null ? idMap['programId'] as String : json['programId'] ?? '',
      name: json['name'] ?? '', // Note: 'name' might not be in DB but useful in UI
      approvalReq: (json['approvalReq'] == 1 || json['approvalReq'] == true),
      preApproveProc: (json['preApproveProc'] == 1 || json['preApproveProc'] == true),
      preExecMethod: json['preExecMethod'],
      preProcessName: json['preProcessName'],
      postApproveProc: (json['postApproveProc'] == 1 || json['postApproveProc'] == true),
      postExecMethod: json['postExecMethod'],
      postProcessName: json['postProcessName'],
      isTran: (json['isTranPgm'] == 1 || json['isTranPgm'] == true || json['isTran'] == 1 || json['isTran'] == true),
      levels: json['levels'] ?? 1,
      orgCode: idMap != null ? idMap['orgCode'] as int? : json['orgCode'],
    );
  }
}


class QueueEntry {
  final String authsl;
  final String type; // 'T' or 'N'
  final String prog;
  final String name;
  final String user;
  final String date;
  final String amount;
  final String level;
  final bool risk;
  final bool locked;
  final bool isNew;

  QueueEntry({
    required this.authsl,
    required this.type,
    required this.prog,
    required this.name,
    required this.user,
    required this.date,
    required this.amount,
    required this.level,
    required this.risk,
    required this.locked,
    required this.isNew,
  });

  QueueEntry copyWith({bool? isNew}) => QueueEntry(
        authsl: authsl,
        type: type,
        prog: prog,
        name: name,
        user: user,
        date: date,
        amount: amount,
        level: level,
        risk: risk,
        locked: locked,
        isNew: isNew ?? this.isNew,
      );
}

class AuthRecord {
  final String orgCode;
  final String effDate;
  final String programId;
  final String primaryKey;
  final String authSl;
  final String displayRemarks;
  final String eUser;
  final String eDate;
  final String? cUser;
  final String? cDate;
  final String? rUser;
  final String? rDate;
  final String? flUser;
  final String? flDate;
  final String? slUser;
  final String? slDate;
  final String? tlUser;
  final String? tlDate;
  final String? exceptionalRemarks;
  final bool correctionReq;
  final String? correctionDetails;
  final bool riskPresented;
  final bool authLock;
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
    this.cUser,
    this.cDate,
    this.rUser,
    this.rDate,
    this.flUser,
    this.flDate,
    this.slUser,
    this.slDate,
    this.tlUser,
    this.tlDate,
    this.exceptionalRemarks,
    this.correctionReq = false,
    this.correctionDetails,
    this.riskPresented = false,
    this.authLock = false,
    required this.dataBlocks,
  });

  String get title => programId;
  String get subtitle => displayRemarks;
  Map<String, dynamic> get details =>
      dataBlocks.isNotEmpty ? dataBlocks.first.data : <String, dynamic>{};

  factory AuthRecord.fromJson(Map<String, dynamic> json) {
    final d = json.map((k, v) => MapEntry(k.toLowerCase(), v));

    List<AuthDataBlock> dataBlocksList = [];
    try {
      var dbData = json['dataBlocks'] ?? json['datablock'] ?? json['dataBlock'] ?? d['datablocks'] ?? d['datablock'];
      if (dbData != null) {
        if (dbData is String && dbData.trim().isNotEmpty) {
          var parsed = jsonDecode(dbData);
          if (parsed is List) {
            for (var item in parsed) {
              if (item is Map<String, dynamic>) {
                dataBlocksList.add(AuthDataBlock.fromJson(item));
              }
            }
          } else if (parsed is Map<String, dynamic>) {
            dataBlocksList.add(AuthDataBlock.fromJson(parsed));
          }
        } else if (dbData is List) {
          for (var item in dbData) {
            if (item is Map<String, dynamic>) {
              dataBlocksList.add(AuthDataBlock.fromJson(item));
            }
          }
        } else if (dbData is Map<String, dynamic>) {
          dataBlocksList.add(AuthDataBlock.fromJson(dbData));
        }
      }
    } catch (e) {
      print('Error parsing dataBlocks for ${json['authSl']}: $e');
    }

    return AuthRecord(
      orgCode: (json['orgCode'] ?? d['orgcode'] ?? '')?.toString() ?? '',
      effDate: (json['effDate'] ?? d['effdate'] ?? '')?.toString() ?? '',
      programId: (json['programId'] ?? d['programid'] ?? '')?.toString() ?? '',
      primaryKey: (json['primaryKey'] ?? d['primarykey'] ?? '')?.toString() ?? '',
      authSl: (json['authSl'] ?? d['authsl'] ?? '')?.toString() ?? '',
      displayRemarks: (json['displayRemarks'] ?? json['display_remarks'] ?? json['remarks'] ?? d['display_remarks'] ?? d['remarks'] ?? d['displayremarks'] ?? '')?.toString() ?? '',
      eUser: (json['eUser'] ?? json['entryUser'] ?? d['euser'] ?? d['entryuser'] ?? '')?.toString() ?? '',
      eDate: (json['eDate'] ?? json['effdate'] ?? json['entryDate'] ?? d['effdate'] ?? d['edate'] ?? d['entrydate'] ?? '')?.toString() ?? '',
      cUser: (json['cUser'] ?? d['cuser'])?.toString(),
      cDate: (json['cDate'] ?? d['cdate'])?.toString(),
      rUser: (json['rUser'] ?? d['ruser'])?.toString(),
      rDate: (json['rDate'] ?? d['rdate'])?.toString(),
      flUser: (json['flUser'] ?? d['fluser'])?.toString(),
      flDate: (json['flDate'] ?? json['flUserDate'] ?? d['fldate'])?.toString(),
      slUser: (json['slUser'] ?? d['sluser'])?.toString(),
      slDate: (json['slDate'] ?? json['slUserDate'] ?? d['sldate'])?.toString(),
      tlUser: (json['tlUser'] ?? d['tluser'])?.toString(),
      tlDate: (json['tlDate'] ?? json['tlUserDate'] ?? d['tldate'])?.toString(),
      exceptionalRemarks: (json['exceptionalRemarks'] ?? d['exceptionalremarks'])?.toString(),
      correctionReq: json['correctionReq'] == true || json['correctionReq'] == 1 || d['correctionreq'] == true || d['correctionreq'] == 1,
      correctionDetails: (json['correctionDetails'] ?? d['correctiondetails'])?.toString(),
      riskPresented: json['riskPresented'] == true || json['riskPresented'] == 1 || d['riskpresented'] == true || d['riskpresented'] == 1,
      authLock: json['authLock'] == true || json['authLock'] == 1 || d['authlock'] == true || d['authlock'] == 1,
      dataBlocks: dataBlocksList,
    );
  }
}

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
    Map<String, dynamic> dataMap = {};
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'];
    } else {
      var dbString = json['dataBlock'] ?? json['datablock'] ?? json['DATABLOCK'];
      if (dbString != null && dbString is String && dbString.trim().isNotEmpty) {
        try {
          dataMap = jsonDecode(dbString);
        } catch (e) {
          dataMap = json;
        }
      } else {
        dataMap = json;
      }
    }

    return AuthDataBlock(
      recSl: json['recSl'] ?? 0,
      tableName: json['tableName'] ?? '',
      data: dataMap,
    );
  }
}
