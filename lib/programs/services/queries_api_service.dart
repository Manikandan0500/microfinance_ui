import 'dart:async';
import '../mock_database.dart';
import '../models/loan_status_history.dart';
import '../models/loan_outstanding_balance.dart';
import '../models/loan_repayment_schedule.dart';

class QueriesApiService {
  static final MockDatabase _db = MockDatabase();

  static Future<List<LoanStatusHistory>> getLoanStatusHistories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _db.loanStatusHistories;
  }

  static Future<List<LoanOutstandingBalance>> getLoanOutstandingBalances() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _db.loanOutstandingBalances;
  }

  static Future<List<LoanRepaymentSchedule>> getLoanRepaymentSchedules() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _db.loanRepaymentSchedules;
  }
}
