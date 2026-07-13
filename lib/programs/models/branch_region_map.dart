class BranchRegionMap {
  String orgCode;
  String branchCode;
  String regionCode;
  bool status;

  BranchRegionMap({
    required this.orgCode,
    required this.branchCode,
    required this.regionCode,
    this.status = true,
  });

  BranchRegionMap copyWith({
    String? orgCode,
    String? branchCode,
    String? regionCode,
    bool? status,
  }) {
    return BranchRegionMap(
      orgCode: orgCode ?? this.orgCode,
      branchCode: branchCode ?? this.branchCode,
      regionCode: regionCode ?? this.regionCode,
      status: status ?? this.status,
    );
  }
}
