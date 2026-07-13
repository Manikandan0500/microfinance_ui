class HeadMenuModel {
  int hMenuCd;
  String hMenuDesc;
  String? hPgmId;
  String? programPath;
  String? menuLocation;
  String menuLogo;
  bool menuStatus;
  String? userName;
  String? euser;
  dynamic edate;
  String? cuser;
  dynamic cdate;
  String? auser;
  dynamic adate;

  HeadMenuModel({
    required this.hMenuCd,
    required this.hMenuDesc,
    this.hPgmId,
    this.programPath,
    this.menuLocation,
    required this.menuLogo,
    required this.menuStatus,
    this.userName,
    this.euser,
    this.edate,
    this.cuser,
    this.cdate,
    this.auser,
    this.adate,
  });

  factory HeadMenuModel.fromJson(Map<String, dynamic> json) {
    return HeadMenuModel(
      hMenuCd: json['hmenuCd'] ?? json['hMenuCd'] ?? 0,
      hMenuDesc: json['hmenuDesc'] ?? json['hMenuDesc'] ?? '',
      hPgmId: json['hpgmId'] ?? json['hPgmId'],
      programPath: json['programPath'],
      menuLocation: json['menuLocation'],
      menuLogo: json['menuLogo'] ?? '',
      menuStatus: json['menuStatus'] == 1 || json['menuStatus'] == true,
      euser: json['euser'],
      edate: json['edate'],
      cuser: json['cuser'],
      cdate: json['cdate'],
      auser: json['auser'],
      adate: json['adate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hmenuCd': hMenuCd,
      'hmenuDesc': hMenuDesc,
      'hpgmId': hPgmId,
      'programPath': programPath,
      'menuLocation': menuLocation,
      'menuLogo': menuLogo,
      'menuStatus': menuStatus ? 1 : 0,
      if (userName != null) 'userName': userName,
      if (euser != null) 'euser': euser,
      if (edate != null) 'edate': edate,
      if (cuser != null) 'cuser': cuser,
      if (cdate != null) 'cdate': cdate,
      if (auser != null) 'auser': auser,
      if (adate != null) 'adate': adate,
    };
  }
}

class MenuModel {
  int hMenuCd;
  int menuCd;
  String menuDescn;
  int? menuOrder;
  bool? subMenuReq;
  String? parentPgmId;
  String? programPath;
  String menuLogo;
  String? userName;
  String? hMenuDesc;
  String? euser;
  dynamic edate;
  String? cuser;
  dynamic cdate;
  String? auser;
  dynamic adate;

  MenuModel({
    required this.hMenuCd,
    required this.menuCd,
    required this.menuDescn,
    this.menuOrder,
    this.subMenuReq,
    this.parentPgmId,
    this.programPath,
    required this.menuLogo,
    this.userName,
    this.hMenuDesc,
    this.euser,
    this.edate,
    this.cuser,
    this.cdate,
    this.auser,
    this.adate,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      hMenuCd: json['hmenuCd'] ?? json['hMenuCd'] ?? 0,
      menuCd: json['menuCd'] ?? 0,
      menuDescn: json['menuDescn'] ?? '',
      menuOrder: json['menuOrder'],
      subMenuReq: json['subMenuReq'],
      parentPgmId: json['parentPgmId'],
      programPath: json['programPath'],
      menuLogo: json['menuLogo'] ?? '',
      hMenuDesc: json['hmenuDesc'] ?? json['hMenuDesc'],
      euser: json['euser'],
      edate: json['edate'],
      cuser: json['cuser'],
      cdate: json['cdate'],
      auser: json['auser'],
      adate: json['adate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hmenuCd': hMenuCd,
      'menuCd': menuCd,
      'menuDescn': menuDescn,
      'menuOrder': menuOrder,
      'subMenuReq': subMenuReq,
      'parentPgmId': parentPgmId,
      'programPath': programPath,
      'menuLogo': menuLogo,
      if (userName != null) 'userName': userName,
      if (euser != null) 'euser': euser,
      if (edate != null) 'edate': edate,
      if (cuser != null) 'cuser': cuser,
      if (cdate != null) 'cdate': cdate,
      if (auser != null) 'auser': auser,
      if (adate != null) 'adate': adate,
    };
  }
}

class SubMenuModel {
  int hMenuCd;
  int menuCd;
  int subMenuCd;
  String menuDescn;
  int? menuOrder;
  String? subMenuPgmId;
  String? programPath;
  String menuLogo;
  String? euser;
  dynamic edate;
  String? cuser;
  dynamic cdate;
  String? auser;
  dynamic adate;
  String? userName;

  SubMenuModel({
    required this.hMenuCd,
    required this.menuCd,
    required this.subMenuCd,
    required this.menuDescn,
    this.menuOrder,
    this.subMenuPgmId,
    this.programPath,
    required this.menuLogo,
    this.userName,
    this.euser,
    this.edate,
    this.cuser,
    this.cdate,
    this.auser,
    this.adate,
  });

  factory SubMenuModel.fromJson(Map<String, dynamic> json) {
    return SubMenuModel(
      hMenuCd: json['hmenuCd'] ?? json['hMenuCd'] ?? 0,
      menuCd: json['menuCd'] ?? 0,
      subMenuCd: json['subMenuCd'] ?? 0,
      menuDescn: json['menuDescn'] ?? '',
      menuOrder: json['menuOrder'],
      subMenuPgmId: json['subMenuPgmId'],
      programPath: json['programPath'],
      menuLogo: json['menuLogo'] ?? '',
      euser: json['euser'],
      edate: json['edate'],
      cuser: json['cuser'],
      cdate: json['cdate'],
      auser: json['auser'],
      adate: json['adate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hmenuCd': hMenuCd,
      'menuCd': menuCd,
      'subMenuCd': subMenuCd,
      'menuDescn': menuDescn,
      'menuOrder': menuOrder,
      'subMenuPgmId': subMenuPgmId,
      'programPath': programPath,
      'menuLogo': menuLogo,
      if (userName != null) 'userName': userName,
      if (euser != null) 'euser': euser,
      if (edate != null) 'edate': edate,
      if (cuser != null) 'cuser': cuser,
      if (cdate != null) 'cdate': cdate,
      if (auser != null) 'auser': auser,
      if (adate != null) 'adate': adate,
    };
  }
}

class MenuProgramModel {
  int hMenuCd;
  int menuCd;
  int subMenuCd;
  String? pgmId;
  String description;
  int? menuOrder;
  String? programPath;
  bool status;
  String menuLogo;
  String? userName;
  String? euser;
  dynamic edate;
  String? cuser;
  dynamic cdate;
  String? auser;
  dynamic adate;

  MenuProgramModel({
    required this.hMenuCd,
    required this.menuCd,
    required this.subMenuCd,
    this.pgmId,
    required this.description,
    this.menuOrder,
    this.programPath,
    required this.status,
    required this.menuLogo,
    this.userName,
    this.euser,
    this.edate,
    this.cuser,
    this.cdate,
    this.auser,
    this.adate,
  });

  factory MenuProgramModel.fromJson(Map<String, dynamic> json) {
    return MenuProgramModel(
      hMenuCd: json['hmenuCd'] ?? json['hMenuCd'] ?? 0,
      menuCd: json['menuCd'] ?? 0,
      subMenuCd: json['subMenuCd'] ?? 0,
      pgmId: json['pgmId'],
      description: json['description'] ?? '',
      menuOrder: json['menuOrder'],
      programPath: json['programPath'],
      status: json['menuStatus'] == 1 || json['status'] == 1,
      menuLogo: json['menuLogo'] ?? '',
      euser: json['euser'],
      edate: json['edate'],
      cuser: json['cuser'],
      cdate: json['cdate'],
      auser: json['auser'],
      adate: json['adate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hmenuCd': hMenuCd,
      'menuCd': menuCd,
      'subMenuCd': subMenuCd,
      'pgmId': pgmId,
      'description': description,
      'menuOrder': menuOrder,
      'programPath': programPath,
      'menuStatus': status ? 1 : 0,
      'menuLogo': menuLogo,
      if (userName != null) 'userName': userName,
      if (euser != null) 'euser': euser,
      if (edate != null) 'edate': edate,
      if (cuser != null) 'cuser': cuser,
      if (cdate != null) 'cdate': cdate,
      if (auser != null) 'auser': auser,
      if (adate != null) 'adate': adate,
    };
  }
}

class ProgramModel {
  int id;
  String programName;

  ProgramModel({required this.id, required this.programName});

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['pgmId'] ?? json['programId'] ?? json['id'] ?? 0,
      programName: json['descn'] ?? json['programName'] ?? '',
    );
  }
}
