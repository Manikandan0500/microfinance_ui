import 'user_access_mapping.dart';

class UserMappingRequest {
  final List<UserAccessMapping> userMappingReq;
  final int? pgmId;

  UserMappingRequest({required this.userMappingReq, this.pgmId});

  Map<String, dynamic> toJson() {
    return {
      'userMappingReq': userMappingReq.map((item) => item.toJson()).toList(),
      if (pgmId != null) 'pgmId': pgmId,
    };
  }
}
