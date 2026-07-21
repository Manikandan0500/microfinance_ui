import '../models/disbursal_queue.dart';
import '../models/pending_disbursal.dart';
import '../mock_database.dart';

class DisbursalApiService {
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

  /// Fetch all Disbursement Queue transactions (DISB002)
  static Future<List<PendingDisbursal>> getPendingDisbursals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(MockDatabase().pendingDisbursals);
  }

  /// Approve a Disbursement Queue transaction
  static Future<void> approvePendingDisbursal(String loanAccountNo) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase().approvePendingDisbursal(loanAccountNo);
  }

  /// Reject a Disbursement Queue transaction
  static Future<void> rejectPendingDisbursal(String loanAccountNo) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase().rejectPendingDisbursal(loanAccountNo);
  }

  /// Submit Disbursement Queue details to Authorization Queue
  static Future<void> submitToAuthQueue(String loanAccountNo, PendingDisbursal updatedRecord, DisbursalQueue updatedQueue) async {
    await Future.delayed(const Duration(milliseconds: 350));
    MockDatabase().submitToAuthQueue(loanAccountNo, updatedRecord, updatedQueue);
  }
}
