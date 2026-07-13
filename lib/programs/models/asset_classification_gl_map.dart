class AssetClassificationGlMap {
  String orgCode;
  String productCode;
  String delinquencyCode;
  String prinGl;
  String intGl;
  String provisionGl;
  bool mapStatus;

  AssetClassificationGlMap({
    required this.orgCode,
    required this.productCode,
    required this.delinquencyCode,
    required this.prinGl,
    required this.intGl,
    required this.provisionGl,
    this.mapStatus = true,
  });

  AssetClassificationGlMap copyWith({
    String? orgCode,
    String? productCode,
    String? delinquencyCode,
    String? prinGl,
    String? intGl,
    String? provisionGl,
    bool? mapStatus,
  }) {
    return AssetClassificationGlMap(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      delinquencyCode: delinquencyCode ?? this.delinquencyCode,
      prinGl: prinGl ?? this.prinGl,
      intGl: intGl ?? this.intGl,
      provisionGl: provisionGl ?? this.provisionGl,
      mapStatus: mapStatus ?? this.mapStatus,
    );
  }
}
