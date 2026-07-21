import 'dart:async';
import '../mock_database.dart';
import '../models/loan_account_master.dart';

class LoanAccountApiService {
  static final MockDatabase _db = MockDatabase();

  static Future<List<LoanAccountMaster>> getLoanAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _db.loanAccounts;
  }

  static Future<void> createLoanAccount(LoanAccountMaster record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final exists = _db.loanAccounts.any((c) => c.loanAccountNo == record.loanAccountNo);
    if (exists) {
      throw Exception('Loan Account with this Account No already exists.');
    }
    _db.addLoanAccount(record);
  }

  static Future<void> updateLoanAccount(LoanAccountMaster record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _db.updateLoanAccount(record);
  }

  static Future<void> deleteLoanAccount(String accountNo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _db.deleteLoanAccount(accountNo);
  }
}
