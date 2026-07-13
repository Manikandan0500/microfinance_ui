class RateRevisionHistory {
  String orgCode;
  String productCode;
  DateTime effDate;
  double revisedRate;
  String benchmarkRateCode;
  double spreadPct;
  String revisionReason;
  bool revisionStatus;

  RateRevisionHistory({
    required this.orgCode,
    required this.productCode,
    required this.effDate,
    required this.revisedRate,
    required this.benchmarkRateCode,
    required this.spreadPct,
    required this.revisionReason,
    this.revisionStatus = true,
  });

  RateRevisionHistory copyWith({
    String? orgCode,
    String? productCode,
    DateTime? effDate,
    double? revisedRate,
    String? benchmarkRateCode,
    double? spreadPct,
    String? revisionReason,
    bool? revisionStatus,
  }) {
    return RateRevisionHistory(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      effDate: effDate ?? this.effDate,
      revisedRate: revisedRate ?? this.revisedRate,
      benchmarkRateCode: benchmarkRateCode ?? this.benchmarkRateCode,
      spreadPct: spreadPct ?? this.spreadPct,
      revisionReason: revisionReason ?? this.revisionReason,
      revisionStatus: revisionStatus ?? this.revisionStatus,
    );
  }
}
