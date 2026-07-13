class PrepaymentForeclosureConfig {
  String orgCode;
  String productCode;
  int lockInPeriodMonths;
  String prepaymentPenaltyType; // Percentage, Fixed
  double prepaymentPenaltyValue;
  String foreclosureFeeType; // Percentage, Fixed
  double foreclosureFeeValue;
  String scheduleRecalcMethod; // Re-amortization, Tenure Reduction
  bool configStatus;

  PrepaymentForeclosureConfig({
    required this.orgCode,
    required this.productCode,
    required this.lockInPeriodMonths,
    required this.prepaymentPenaltyType,
    required this.prepaymentPenaltyValue,
    required this.foreclosureFeeType,
    required this.foreclosureFeeValue,
    required this.scheduleRecalcMethod,
    this.configStatus = true,
  });

  PrepaymentForeclosureConfig copyWith({
    String? orgCode,
    String? productCode,
    int? lockInPeriodMonths,
    String? prepaymentPenaltyType,
    double? prepaymentPenaltyValue,
    String? foreclosureFeeType,
    double? foreclosureFeeValue,
    String? scheduleRecalcMethod,
    bool? configStatus,
  }) {
    return PrepaymentForeclosureConfig(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      lockInPeriodMonths: lockInPeriodMonths ?? this.lockInPeriodMonths,
      prepaymentPenaltyType: prepaymentPenaltyType ?? this.prepaymentPenaltyType,
      prepaymentPenaltyValue: prepaymentPenaltyValue ?? this.prepaymentPenaltyValue,
      foreclosureFeeType: foreclosureFeeType ?? this.foreclosureFeeType,
      foreclosureFeeValue: foreclosureFeeValue ?? this.foreclosureFeeValue,
      scheduleRecalcMethod: scheduleRecalcMethod ?? this.scheduleRecalcMethod,
      configStatus: configStatus ?? this.configStatus,
    );
  }
}
