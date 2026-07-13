class DelinquencyBucketMaster {
  String orgCode;
  String productCode;
  String delinquencyCode;
  String bucketLabel;
  int overdueDaysFrom;
  int overdueDaysTo;
  int stageOrder;
  bool isNpaFlag;
  double provisionPct;
  bool bucketStatus;

  DelinquencyBucketMaster({
    required this.orgCode,
    required this.productCode,
    required this.delinquencyCode,
    required this.bucketLabel,
    required this.overdueDaysFrom,
    required this.overdueDaysTo,
    required this.stageOrder,
    required this.isNpaFlag,
    required this.provisionPct,
    this.bucketStatus = true,
  });

  DelinquencyBucketMaster copyWith({
    String? orgCode,
    String? productCode,
    String? delinquencyCode,
    String? bucketLabel,
    int? overdueDaysFrom,
    int? overdueDaysTo,
    int? stageOrder,
    bool? isNpaFlag,
    double? provisionPct,
    bool? bucketStatus,
  }) {
    return DelinquencyBucketMaster(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      delinquencyCode: delinquencyCode ?? this.delinquencyCode,
      bucketLabel: bucketLabel ?? this.bucketLabel,
      overdueDaysFrom: overdueDaysFrom ?? this.overdueDaysFrom,
      overdueDaysTo: overdueDaysTo ?? this.overdueDaysTo,
      stageOrder: stageOrder ?? this.stageOrder,
      isNpaFlag: isNpaFlag ?? this.isNpaFlag,
      provisionPct: provisionPct ?? this.provisionPct,
      bucketStatus: bucketStatus ?? this.bucketStatus,
    );
  }
}
