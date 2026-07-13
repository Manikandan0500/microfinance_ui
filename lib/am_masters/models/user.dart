class User {
  final String id;
  final String email;
  final String? name;
  final int? orgCode;
  final String? userScd;
  final int? menuType;
  final String? gender;
  final String? title;
  final String? fName;
  final String? mName;
  final String? lName;
  final String? mobile;
  final String? country;
  final String? userName;
  final bool? isOnline;
  final String? lastSeen;
  final String? roleType;
  final String? picture;
  final List<Map<String, dynamic>>? products;

  User({
    required this.id,
    required this.email,
    this.name,
    this.orgCode,
    this.userScd,
    this.menuType,
    this.gender,
    this.title,
    this.fName,
    this.mName,
    this.lName,
    this.mobile,
    this.country,
    this.userName,
    this.isOnline,
    this.lastSeen,
    this.roleType,
    this.products,
    this.picture
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    String fullName = '';
    if (json['fName'] != null || json['lName'] != null) {
      fullName = '${json['fName'] ?? ''} ${json['lName'] ?? ''}'.trim();
    }

    List<Map<String, dynamic>>? products;
    if (json['products'] != null) {
      products = List<Map<String, dynamic>>.from(
        (json['products'] as List).map((p) => Map<String, dynamic>.from(p as Map)),
      );
    }

    return User(
      id: json['userScd']?.toString() ?? json['userscd']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      name: fullName.isNotEmpty ? fullName : json['name'] ?? json['Name'],
      orgCode: parseInt(json['orgCode'] ?? json['orgcode'] ?? json['org_code']),
      // userScd: parseInt(json['userScd'] ?? json['userscd'] ?? json['user_scd'] ?? json['userCode'] ?? json['id']),
      userScd: (
  json['userScd'] ??
  json['userscd'] ??
  json['user_scd'] ??
  json['userCode'] ??
  json['id']
)?.toString(),
      menuType: parseInt(json['menuType'] ?? json['menu_type']),
      gender: json['gender'] as String? ?? json['Gender'] as String?,
      title: json['title'] as String? ?? json['Title'] as String?,
      fName: json['fName'] as String? ?? json['fname'] as String?,
      mName: json['mName'] as String? ?? json['mname'] as String?,
      lName: json['lName'] as String? ?? json['lname'] as String?,
      mobile: json['mobile'] as String?,
      country: json['country'] as String?,
      userName: json['userName'] as String?,
      isOnline: json['isOnline'] is bool ? json['isOnline'] as bool : null,
      lastSeen: json['lastSeen'] as String?,
      roleType: (json['roleType'] ?? json['roletype'] ?? json['role_type'])?.toString(),
      picture:json['picture'] as String?,
      products: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'orgCode': orgCode,
      'userScd': userScd,
      'menuType': menuType,
      'gender': gender,
      'title': title,
      'fName': fName,
      'mName': mName,
      'lName': lName,
      'mobile': mobile,
      'country': country,
      'userName': userName,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'roleType': roleType,
      'picture':'picture',
      'products': products,
    };
  }
}
