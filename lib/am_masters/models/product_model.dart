class ProductModel {
  final int orgCode;
  final int productCode;
  final String productName;
  final String homeUrl;
  final bool status;
  String? logo;
  final String country;
  final String? userscd;
  final int? accesscd;
  String? userName;
  String? cuser, cdate, euser, edate, auser, adate;
  final int? pgmId;

  ProductModel({
    required this.orgCode,
    required this.productCode,
    required this.productName,
    required this.homeUrl,
    required this.status,
    this.logo,
    this.country = '',
    this.userscd,
    this.accesscd,
    this.userName,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.pgmId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ProductModel(
      orgCode: parseInt(json['orgcode'] ?? json['orgCode']),
      productCode: parseInt(json['prodcode'] ?? json['productCode']),
      productName:
          json['prodname']?.toString() ?? json['productName']?.toString() ?? '',
      homeUrl:
          json['homeUrl']?.toString() ?? json['home_url']?.toString() ?? '',
      status: json['status'] == true,
      country: json['country']?.toString() ?? '',
      logo: json['logo']?.toString(),
      userscd: json['userscd']?.toString(),
      accesscd: parseInt(json['accesscd']),
      userName: json['userName']?.toString(),
      cuser: json['cuser']?.toString(),
      cdate: json['cdate']?.toString(),
      euser: json['euser']?.toString(),
      edate: json['edate']?.toString(),
      auser: json['auser']?.toString(),
      adate: json['adate']?.toString(),
      pgmId: parseInt(json['pgmId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgcode': orgCode,
      'prodcode': productCode,
      'prodname': productName,
      'homeUrl': homeUrl,
      'status': status,
      'logo': logo,
      'userscd': userscd,
      'accesscd': accesscd,
      'userName': userName,
      'cuser': cuser,
      'cdate': cdate,
      'euser': euser,
      'edate': edate,
      'auser': auser,
      'adate': adate,
      if (pgmId != null) 'pgmId': pgmId,
    };
  }
}
