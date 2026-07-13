class LoanProductMaster {
  String orgCode;
  String productCode;
  String productName;
  double minAmount;
  double maxAmount;
  double interestRate;
  String interestType; // Flat, Reducing
  String rateType; // Fixed, Floating
  String benchmarkRateCode;
  int minTenureMonths;
  int maxTenureMonths;
  String repayFrequency; // Monthly, Weekly, Fortnightly
  String prinGl;
  String intGl;
  String penalGl;
  bool productStatus;

  LoanProductMaster({
    required this.orgCode,
    required this.productCode,
    required this.productName,
    required this.minAmount,
    required this.maxAmount,
    required this.interestRate,
    required this.interestType,
    required this.rateType,
    required this.benchmarkRateCode,
    required this.minTenureMonths,
    required this.maxTenureMonths,
    required this.repayFrequency,
    required this.prinGl,
    required this.intGl,
    required this.penalGl,
    this.productStatus = true,
  });

  LoanProductMaster copyWith({
    String? orgCode,
    String? productCode,
    String? productName,
    double? minAmount,
    double? maxAmount,
    double? interestRate,
    String? interestType,
    String? rateType,
    String? benchmarkRateCode,
    int? minTenureMonths,
    int? maxTenureMonths,
    String? repayFrequency,
    String? prinGl,
    String? intGl,
    String? penalGl,
    bool? productStatus,
  }) {
    return LoanProductMaster(
      orgCode: orgCode ?? this.orgCode,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      rateType: rateType ?? this.rateType,
      benchmarkRateCode: benchmarkRateCode ?? this.benchmarkRateCode,
      minTenureMonths: minTenureMonths ?? this.minTenureMonths,
      maxTenureMonths: maxTenureMonths ?? this.maxTenureMonths,
      repayFrequency: repayFrequency ?? this.repayFrequency,
      prinGl: prinGl ?? this.prinGl,
      intGl: intGl ?? this.intGl,
      penalGl: penalGl ?? this.penalGl,
      productStatus: productStatus ?? this.productStatus,
    );
  }
}
