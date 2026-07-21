class PendingDisbursal {
  String orgCode;
  String loanAccountNo;
  int disbursementSeqNo;
  double disbursementAmount;
  String currencyCode;
  String disbursementMode;
  String? bankRefNo;
  String disbursedByUserId;
  DateTime disbursementDate;
  String disbursementStatus;
  String? accPostingRef;
  String? accPostingStatus;

  PendingDisbursal({
    required this.orgCode,
    required this.loanAccountNo,
    required this.disbursementSeqNo,
    required this.disbursementAmount,
    required this.currencyCode,
    required this.disbursementMode,
    this.bankRefNo,
    required this.disbursedByUserId,
    required this.disbursementDate,
    required this.disbursementStatus,
    this.accPostingRef,
    this.accPostingStatus,
  });

  PendingDisbursal copyWith({
    String? orgCode,
    String? loanAccountNo,
    int? disbursementSeqNo,
    double? disbursementAmount,
    String? currencyCode,
    String? disbursementMode,
    String? bankRefNo,
    String? disbursedByUserId,
    DateTime? disbursementDate,
    String? disbursementStatus,
    String? accPostingRef,
    String? accPostingStatus,
  }) {
    return PendingDisbursal(
      orgCode: orgCode ?? this.orgCode,
      loanAccountNo: loanAccountNo ?? this.loanAccountNo,
      disbursementSeqNo: disbursementSeqNo ?? this.disbursementSeqNo,
      disbursementAmount: disbursementAmount ?? this.disbursementAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      disbursementMode: disbursementMode ?? this.disbursementMode,
      bankRefNo: bankRefNo ?? this.bankRefNo,
      disbursedByUserId: disbursedByUserId ?? this.disbursedByUserId,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      disbursementStatus: disbursementStatus ?? this.disbursementStatus,
      accPostingRef: accPostingRef ?? this.accPostingRef,
      accPostingStatus: accPostingStatus ?? this.accPostingStatus,
    );
  }
}
