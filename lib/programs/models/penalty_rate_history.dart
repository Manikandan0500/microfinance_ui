class PenaltyRateHistory {
  String orgCode;
  String productCode;
  String delinquencyCode;
  DateTime effDate;
  String penaltyType; // Percentage, Fixed
  double penaltyValue;
  bool rateStatus;

  PenaltyRateHistory({
    required this.orgCode,
    required this.productCode,
    required this.delinquencyCode,
    required this.effDate,
    required this.penaltyType,
    required this.penaltyValue,
    this.rateStatus = true,
  });

  PenaltyRateHistory copyWith({
    String? orgCode,
    String? productCode,
    String? delinquencyCode,
    DateTime? effDate,
    String? penaltyType,
    double? penaltyValue,
    bool? rateStatus,
  }) {
    return PenaltyRateHistory(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      delinquencyCode: delinquencyCode ?? this.delinquencyCode,
      effDate: effDate ?? this.effDate,
      penaltyType: penaltyType ?? this.penaltyType,
      penaltyValue: penaltyValue ?? this.penaltyValue,
      rateStatus: rateStatus ?? this.rateStatus,
    );
  }
}
