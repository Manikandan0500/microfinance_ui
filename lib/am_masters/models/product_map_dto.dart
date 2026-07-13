class ProductMapDto {
  int? orgcode;
  int? prodcode;
  bool? status;

  ProductMapDto({
    this.orgcode,
    this.prodcode,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'orgcode': orgcode,
      'prodcode': prodcode,
      'status': status,
    };
  }

  factory ProductMapDto.fromJson(Map<String, dynamic> json) {
    return ProductMapDto(
      orgcode: json['orgcode'] as int?,
      prodcode: json['prodcode'] as int?,
      status: json['status'] as bool?,
    );
  }
}
