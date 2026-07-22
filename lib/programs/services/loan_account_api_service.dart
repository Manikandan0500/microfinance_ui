import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../am_masters/services/auth_service.dart';
import '../models/loan_application.dart';

class LoanAccountApiService {
  static const String _baseUrl = 'http://localhost:8085/api/loan-application';

  static LoanApplication _fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      orgCode: json['orgcode']?.toString() ?? json['orgCode']?.toString() ?? '101',
      queueId: json['queue_id']?.toString() ?? json['queueId']?.toString() ?? '',
      sourceSystem: json['source_system']?.toString() ?? json['sourceSystem']?.toString() ?? 'MANUAL',
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      groupCode: json['group_code']?.toString() ?? json['groupCode']?.toString(),
      productCode: json['product_code']?.toString() ?? json['productCode']?.toString() ?? '',
      approvedAmount: (json['approved_amount'] as num?)?.toDouble() ?? (json['approvedAmount'] as num?)?.toDouble() ?? 0.0,
      approvedTenureMonths: (json['approved_tenure_months'] as num?)?.toInt() ?? (json['approvedTenureMonths'] as num?)?.toInt() ?? 0,
      approvedInterestRate: (json['approved_interest_rate'] as num?)?.toDouble() ?? (json['approvedInterestRate'] as num?)?.toDouble() ?? 0.0,
      queueDate: json['queue_date'] != null ? DateTime.parse(json['queue_date']) : (json['queueDate'] != null ? DateTime.parse(json['queueDate']) : DateTime.now()),
      assignedToUserId: json['assigned_to_user_id']?.toString() ?? json['assignedToUserId']?.toString(),
      disbursementStatus: json['disbursement_status']?.toString() ?? json['disbursementStatus']?.toString() ?? 'Pending',
      currencyCode: json['currency_code']?.toString() ?? json['currencyCode']?.toString() ?? 'INR',
    );
  }

  static Map<String, dynamic> _toJson(LoanApplication record) {
    final user = AuthService().currentUser;
    final userName = [user?.fName, user?.mName, user?.lName].where((e) => e != null && e.isNotEmpty).join(' ');

    return {
      'orgcode': int.tryParse(record.orgCode) ?? 101,
      'queue_id': record.queueId,
      'source_system': record.sourceSystem,
      'client_id': record.clientId,
      'group_code': record.groupCode,
      'product_code': record.productCode,
      'approved_amount': record.approvedAmount,
      'approved_tenure_months': record.approvedTenureMonths,
      'approved_interest_rate': record.approvedInterestRate,
      'queue_date': record.queueDate.toIso8601String().substring(0, 10),
      'assigned_to_user_id': record.assignedToUserId,
      'disbursement_status': record.disbursementStatus,
      'currency_code': record.currencyCode,
      'user_name': userName.isNotEmpty ? userName : (user?.name ?? user?.email ?? 'SYS'),
    };
  }

  static Future<List<LoanApplication>> getLoanAccounts() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load loan applications');
  }

  static Future<String?> createLoanAccount(LoanApplication record) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(record)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to create loan application: ${response.body}');
  }

  static Future<String?> updateLoanAccount(LoanApplication record) async {
    final response = await http.put(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(record)),
    );
    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to update loan application: ${response.body}');
  }

  static Future<void> deleteLoanAccount(String queueId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/101/$queueId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete loan application');
    }
  }
}
