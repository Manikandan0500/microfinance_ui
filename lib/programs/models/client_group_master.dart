class ClientGroupMemberMap {
  final String orgCode;
  final String groupCode;
  final String clientId;
  final String memberRole;
  final DateTime joinDate;
  final String memberStatus;

  ClientGroupMemberMap({
    required this.orgCode,
    required this.groupCode,
    required this.clientId,
    required this.memberRole,
    required this.joinDate,
    required this.memberStatus,
  });

  factory ClientGroupMemberMap.fromJson(Map<String, dynamic> json) {
    return ClientGroupMemberMap(
      orgCode: json['orgCode'] ?? '',
      groupCode: json['groupCode'] ?? '',
      clientId: json['clientId'] ?? '',
      memberRole: json['memberRole'] ?? '',
      joinDate: json['joinDate'] != null ? DateTime.parse(json['joinDate']) : DateTime.now(),
      memberStatus: json['memberStatus'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgCode': orgCode,
      'groupCode': groupCode,
      'clientId': clientId,
      'memberRole': memberRole,
      'joinDate': joinDate.toIso8601String(),
      'memberStatus': memberStatus,
    };
  }
}

class ClientGroupMaster {
  final String orgCode;
  final String groupCode;
  final String groupName;
  final String branchCode;
  final String regionCode;
  final String regionalOfficerId;
  final String sourceSystem;
  final String? sourceRefNo;
  final String meetingDay;
  final String meetingFrequency;
  final String groupStatus;
  
  final List<ClientGroupMemberMap> members;

  ClientGroupMaster({
    required this.orgCode,
    required this.groupCode,
    required this.groupName,
    required this.branchCode,
    required this.regionCode,
    required this.regionalOfficerId,
    required this.sourceSystem,
    this.sourceRefNo,
    required this.meetingDay,
    required this.meetingFrequency,
    required this.groupStatus,
    this.members = const [],
  });

  factory ClientGroupMaster.fromJson(Map<String, dynamic> json) {
    return ClientGroupMaster(
      orgCode: json['orgCode'] ?? '',
      groupCode: json['groupCode'] ?? '',
      groupName: json['groupName'] ?? '',
      branchCode: json['branchCode']?.toString() ?? '',
      regionCode: json['regionCode'] ?? '',
      regionalOfficerId: json['regionalOfficerId'] ?? '',
      sourceSystem: json['sourceSystem'] ?? '',
      sourceRefNo: json['sourceRefNo'],
      meetingDay: json['meetingDay'] ?? '',
      meetingFrequency: json['meetingFrequency'] ?? '',
      groupStatus: json['groupStatus'] ?? 'A',
      members: (json['members'] as List<dynamic>?)?.map((e) => ClientGroupMemberMap.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgCode': orgCode,
      'groupCode': groupCode,
      'groupName': groupName,
      'branchCode': branchCode,
      'regionCode': regionCode,
      'regionalOfficerId': regionalOfficerId,
      'sourceSystem': sourceSystem,
      'sourceRefNo': sourceRefNo,
      'meetingDay': meetingDay,
      'meetingFrequency': meetingFrequency,
      'groupStatus': groupStatus,
      'members': members.map((e) => e.toJson()).toList(),
    };
  }
}
