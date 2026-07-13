class RegionMaster {
  String orgCode;
  String regionCode;
  String regionName;
  String state;
  String zone;
  bool status;

  RegionMaster({
    required this.orgCode,
    required this.regionCode,
    required this.regionName,
    required this.state,
    required this.zone,
    this.status = true,
  });

  RegionMaster copyWith({
    String? orgCode,
    String? regionCode,
    String? regionName,
    String? state,
    String? zone,
    bool? status,
  }) {
    return RegionMaster(
      orgCode: orgCode ?? this.orgCode,
      regionCode: regionCode ?? this.regionCode,
      regionName: regionName ?? this.regionName,
      state: state ?? this.state,
      zone: zone ?? this.zone,
      status: status ?? this.status,
    );
  }
}
