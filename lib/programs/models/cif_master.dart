class CifMaster {
  final String orgCode;
  final String cifId;
  final String custType;
  final String title;
  final String firstName;
  final String middleName;

  CifMaster({
    required this.orgCode,
    required this.cifId,
    required this.custType,
    required this.title,
    required this.firstName,
    required this.middleName,
  });

  factory CifMaster.fromJson(Map<String, dynamic> json) {
    return CifMaster(
      orgCode: json['id']?['orgcode']?.toString() ?? '101',
      cifId: json['id']?['cifid']?.toString() ?? '',
      custType: json['custtype'] ?? '',
      title: json['title'] ?? '',
      firstName: json['firstname'] ?? '',
      middleName: json['middlename'] ?? '',
    );
  }

  String get fullName {
    final parts = [title, firstName, middleName].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }
}
