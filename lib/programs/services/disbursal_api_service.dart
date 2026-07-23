import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';
import '../mock_database.dart';

class DisbursalApiService {
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static int get _userOrgCode => AuthService().currentUser?.orgCode ?? 101;

  // ── Mock group data for Group (G) client type ──────────────────────────────
  static const List<Map<String, String>> mockGroups = [
    {'id': 'GRP-001', 'name': 'GRP-001 – Sunrise SHG'},
    {'id': 'GRP-002', 'name': 'GRP-002 – Mahila Mandal'},
    {'id': 'GRP-003', 'name': 'GRP-003 – Grameen JLG'},
    {'id': 'GRP-004', 'name': 'GRP-004 – Pragati Vikas'},
    {'id': 'GRP-005', 'name': 'GRP-005 – Sahayak Samiti'},
  ];

  /// Fetch mock group list (for Group client type)
  static Future<List<Map<String, String>>> getGroups() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return mockGroups;
  }

  /// Fetch all disbursal queue records (DISB001)
  static Future<List<DisbursalQueue>> getDisbursalQueue() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(MockDatabase().disbursalQueue);
  }

  /// Create a new disbursal queue record (Initiate)
  static Future<void> createDisbursalQueue(DisbursalQueue record) async {
    await Future.delayed(const Duration(milliseconds: 300));
    MockDatabase().addDisbursalQueue(record);
  }

  /// Update a disbursal queue record
  static Future<void> updateDisbursalQueue(DisbursalQueue record) async {
    await Future.delayed(const Duration(milliseconds: 300));
    MockDatabase().updateDisbursalQueue(record);
  }

  /// Delete a disbursal queue record
  static Future<void> deleteDisbursalQueue(String queueId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    MockDatabase().deleteDisbursalQueue(queueId);
  }

  /// Fetch all Disbursement Queue transactions (DISB002) from backend
  static Future<List<PendingDisbursal>> getPendingDisbursals() async {
    final orgCode = _userOrgCode;
    final url = Uri.parse('${AppConfig.instance.baseUrl}/api/master/getPendingDisbursementQueue/$orgCode');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      // Update MockDatabase cache so _findQueueFor matches them
      final db = MockDatabase();
      db.disbursalQueue.clear();

      final List<PendingDisbursal> list = [];
      for (final json in data) {
        final Map<String, dynamic> map = json as Map<String, dynamic>;
        
        final org = (map['orgcode'] ?? map['orgCode'] ?? orgCode).toString();
        final clientId = (map['client_id'] ?? map['clientId'] ?? '').toString();
        final queueId = (map['queue_id'] ?? map['queueId'] ?? '').toString();
        final sourceSystem = (map['source_system'] ?? map['sourceSystem'] ?? 'MANUAL').toString();
        final sourceRefNo = (map['source_ref_no'] ?? map['sourceRefNo'])?.toString();
        final groupCode = (map['group_code'] ?? map['groupCode'])?.toString();
        final productCode = (map['product_code'] ?? map['productCode'] ?? '').toString();
        final approvedAmount = double.tryParse((map['approved_amount'] ?? map['approvedAmount'] ?? '0').toString()) ?? 0.0;
        final approvedTenureMonths = int.tryParse((map['approved_tenure_months'] ?? map['approvedTenureMonths'] ?? '12').toString()) ?? 12;
        final approvedInterestRate = double.tryParse((map['approved_interest_rate'] ?? map['approvedInterestRate'] ?? '12').toString()) ?? 12.0;
        
        DateTime queueDate = DateTime.now();
        final qDateStr = map['queue_date'] ?? map['queueDate'];
        if (qDateStr != null) {
          try {
            queueDate = DateTime.parse(qDateStr.toString());
          } catch (_) {}
        }
        
        final assignedTo = (map['assigned_to_user_id'] ?? map['assignedToUserId'])?.toString();
        final disbursementStatus = (map['disbursement_status'] ?? map['disbursementStatus'] ?? 'Pending Input').toString();
        final currencyCode = (map['currency_code'] ?? map['currencyCode'] ?? 'INR').toString();

        final qRecord = DisbursalQueue(
          orgCode: org,
          queueId: queueId,
          clientType: (groupCode != null && groupCode.isNotEmpty) ? 'G' : 'I',
          sourceSystem: sourceSystem,
          sourceRefNo: sourceRefNo,
          clientId: clientId,
          groupCode: groupCode,
          productCode: productCode,
          approvedAmount: approvedAmount,
          approvedTenureMonths: approvedTenureMonths,
          approvedInterestRate: approvedInterestRate,
          queuedDate: queueDate,
          assignedToUserId: assignedTo,
          disbursementStatus: disbursementStatus,
        );
        db.disbursalQueue.add(qRecord);

        list.add(PendingDisbursal(
          orgCode: org,
          loanAccountNo: 'L-$clientId',
          disbursementSeqNo: 1,
          disbursementAmount: approvedAmount,
          currencyCode: currencyCode,
          disbursementMode: 'Bank',
          bankRefNo: '',
          disbursedByUserId: 'Amit Sharma',
          disbursementDate: DateTime.now(),
          disbursementStatus: disbursementStatus == 'PENDING' ? 'Pending Input' : disbursementStatus,
          accPostingRef: '',
          accPostingStatus: 'Pending',
        ));
      }
      return list;
    }
    throw Exception('Failed to load pending queue: ${response.statusCode}');
  }

  /// Complete Disbursement (POST /completeDisbursement)
  static Future<void> completeDisbursement({
    required PendingDisbursal pending,
    required DisbursalQueue queue,
    required List<dynamic> repaymentSchedule,
  }) async {
    final user = AuthService().currentUser;
    final userName = [user?.fName, user?.mName, user?.lName].where((e) => e != null && e.isNotEmpty).join(' ');
    final currentUserName = userName.isNotEmpty ? userName : (user?.name ?? user?.email ?? 'Amit Sharma');
    final formattedDate = DateTime.now().toIso8601String().substring(0, 10);

    final payload = {
      'orgcode': int.tryParse(pending.orgCode) ?? _userOrgCode,
      'queue_id': queue.queueId,
      'loan_account_no': pending.loanAccountNo,
      'disbursement_amount': pending.disbursementAmount,
      'currency_code': pending.currencyCode,
      'disbursement_mode': pending.disbursementMode.toUpperCase(),
      'bank_ref_no': pending.bankRefNo ?? '',
      'disbursed_by_user_id': pending.disbursedByUserId,
      'disbursement_date': pending.disbursementDate.toIso8601String().substring(0, 10),
      'disbursement_status': 'COMPLETED',
      'acc_posting_ref': '',
      'acc_posting_status': 'PENDING',
      'euser': currentUserName,
      'edate': formattedDate,
      'principal_outstanding': pending.disbursementAmount,
      'interest_outstanding': 0.00,
      'total_outstanding': pending.disbursementAmount,
      'repaymentSchedule': repaymentSchedule.map((item) {
        return {
          'installment_no': item.installmentNo,
          'due_date': item.dueDate.toIso8601String().substring(0, 10),
          'principal_due': item.principalDue,
          'interest_due': item.interestDue,
          'total_due': item.totalDue,
          'principal_paid': 0.0,
          'interest_paid': 0.0,
          'installment_status': 'PENDING',
        };
      }).toList(),
    };

    final url = Uri.parse('${AppConfig.instance.baseUrl}/api/master/completeDisbursement');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errMsg = 'Failed to complete disbursement';
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('message')) {
          errMsg = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  /// Approve a Disbursement Queue transaction (Left intact for other parts if needed)
  static Future<void> approvePendingDisbursal(String loanAccountNo) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase().approvePendingDisbursal(loanAccountNo);
  }

  /// Reject a Disbursement Queue transaction (Left intact for other parts if needed)
  static Future<void> rejectPendingDisbursal(String loanAccountNo) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase().rejectPendingDisbursal(loanAccountNo);
  }

  /// Submit Disbursement Queue details to Authorization Queue (Left intact for other parts if needed)
  static Future<void> submitToAuthQueue(String loanAccountNo,
      PendingDisbursal updatedRecord, DisbursalQueue updatedQueue) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase()
        .submitToAuthQueue(loanAccountNo, updatedRecord, updatedQueue);
  }
}
