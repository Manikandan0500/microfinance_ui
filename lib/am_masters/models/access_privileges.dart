class AccessPrivileges {
  final bool viewAccess;
  final bool authAccess;
  final bool makerAccess;
  final bool adminAccess;
  final bool sysAdminAccess;

  AccessPrivileges({
    this.viewAccess = false,
    this.authAccess = false,
    this.makerAccess = false,
    this.adminAccess = false,
    this.sysAdminAccess = false,
  });

  factory AccessPrivileges.fromJson(Map<String, dynamic> json) {
    return AccessPrivileges(
      viewAccess: json['viewaccess'] == true || json['viewaccess'] == 1,
      authAccess: json['authaccess'] == true || json['authaccess'] == 1,
      makerAccess: json['makeraccess'] == true || json['makeraccess'] == 1,
      adminAccess: json['adminaccess'] == true || json['adminaccess'] == 1,
      sysAdminAccess: json['sysadminaccess'] == true || json['sysadminaccess'] == 1,
    );
  }

  bool get canView => viewAccess || adminAccess || sysAdminAccess;
  bool get canEdit => makerAccess || adminAccess || sysAdminAccess;
  bool get canCreate => makerAccess || adminAccess || sysAdminAccess;
  bool get canDelete => makerAccess || adminAccess || sysAdminAccess;
  bool get canAuthorize => authAccess || adminAccess || sysAdminAccess;
}
