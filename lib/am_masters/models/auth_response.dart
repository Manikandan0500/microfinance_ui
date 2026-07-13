class AuthResponse {
  final String? motherToken;
  String? childToken;
  final String? refreshToken;
  final String? userScd;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? email;
  final int? orgCode;
  final String? roleType;
  Map<String, dynamic>? sessionData;

  AuthResponse({
    this.motherToken,
    this.childToken,
    this.refreshToken,
    this.userScd,
    this.firstName,
    this.lastName,
    this.email,
    this.orgCode,
    this.sessionData,
    this.roleType,
     this.userName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    final sessionJson = json['session_data'] as Map<String, dynamic>?;

    // Helper function to parse int from dynamic value
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AuthResponse(
      motherToken: json['mother_token'] as String? ?? json['access_token'] as String?,
      childToken: json['child_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      userScd: userJson != null
    ? userJson['userScd']?.toString()
    : sessionJson != null
        ? sessionJson['userScd']?.toString()
        : null,
      firstName: userJson?['firstName'] as String?,
      lastName: userJson?['lastName'] as String?,
      roleType: json['roleType'] as String? ?? userJson?['roleType'] as String?,
      email: userJson?['email'] as String? ?? sessionJson?['email'] as String?,
      orgCode: userJson != null ? parseInt(userJson['orgCode']) : sessionJson != null ? parseInt(sessionJson['orgCode']) : null,
      sessionData: sessionJson,
      userName: userJson?['userName'] as String?,
    );
  }

}

