import 'package:flutter/foundation.dart';

import 'models/region_master.dart';
import 'models/branch_region_map.dart';
import 'models/loan_product_master.dart';
import 'models/delinquency_bucket_master.dart';
import 'models/penalty_rate_history.dart';
import 'models/asset_classification_gl_map.dart';
import 'models/prepayment_foreclosure_config.dart';
import 'models/rate_revision_history.dart';
import 'models/holiday_calendar.dart';
import 'models/auth_models.dart';
import 'models/disbursal_queue.dart';
import 'models/pending_disbursal.dart';
import 'models/client_group_master.dart';
import 'models/loan_account_master.dart';
import 'models/loan_status_history.dart';
import 'models/loan_outstanding_balance.dart';
import 'models/loan_repayment_schedule.dart';

export 'models/region_master.dart';
export 'models/branch_region_map.dart';
export 'models/loan_product_master.dart';
export 'models/delinquency_bucket_master.dart';
export 'models/penalty_rate_history.dart';
export 'models/asset_classification_gl_map.dart';
export 'models/prepayment_foreclosure_config.dart';
export 'models/rate_revision_history.dart';
export 'models/holiday_calendar.dart';
export 'models/auth_models.dart';
export 'models/disbursal_queue.dart';
export 'models/pending_disbursal.dart';
export 'models/client_group_master.dart';


// --- Mock Database (In-Memory State Store) ---
class MockDatabase extends ChangeNotifier {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  final List<LoanAccountMaster> loanAccounts = [
    LoanAccountMaster(orgCode: '101', loanAccountNo: 'L-2023-001', clientId: 'C-001', productCode: 'JLG', disbursedAmount: 25000, disbursementDate: DateTime(2023, 1, 10), maturityDate: DateTime(2024, 1, 10), loanStatus: 'Active', outstandingPrincipal: 15000, outstandingInterest: 1200, currentDelinquencyCode: 'STD', eUser: 'SYS', eDate: DateTime(2023, 1, 10)),
    LoanAccountMaster(orgCode: '101', loanAccountNo: 'L-2023-002', clientId: 'C-002', productCode: 'JLG', disbursedAmount: 25000, disbursementDate: DateTime(2023, 2, 5), maturityDate: DateTime(2024, 2, 5), loanStatus: 'Active', outstandingPrincipal: 8000, outstandingInterest: 400, currentDelinquencyCode: 'STD', eUser: 'SYS', eDate: DateTime(2023, 2, 5)),
    LoanAccountMaster(orgCode: '101', loanAccountNo: 'L-2023-003', clientId: 'C-003', productCode: 'PL', disbursedAmount: 50000, disbursementDate: DateTime(2022, 6, 1), maturityDate: DateTime(2023, 6, 1), loanStatus: 'Closed', outstandingPrincipal: 0, outstandingInterest: 0, eUser: 'SYS', eDate: DateTime(2022, 6, 1)),
  ];

  final List<LoanStatusHistory> loanStatusHistories = [
    LoanStatusHistory(orgCode: '101', loanAccountNo: 'L-2023-001', statusSeqNo: 1, statusFrom: null, statusTo: 'Active', changedDate: DateTime(2023, 1, 10), changedBy: 'USR01', eUser: 'SYS', eDate: DateTime(2023, 1, 10)),
    LoanStatusHistory(orgCode: '101', loanAccountNo: 'L-2023-001', statusSeqNo: 2, statusFrom: 'Active', statusTo: 'NPA', changedDate: DateTime(2023, 6, 15), changedBy: 'USR02', remarks: 'Missed 3 payments', eUser: 'SYS', eDate: DateTime(2023, 6, 15)),
    LoanStatusHistory(orgCode: '101', loanAccountNo: 'L-2023-002', statusSeqNo: 1, statusFrom: null, statusTo: 'Active', changedDate: DateTime(2023, 2, 5), changedBy: 'USR01', eUser: 'SYS', eDate: DateTime(2023, 2, 5)),
  ];

  final List<LoanOutstandingBalance> loanOutstandingBalances = [
    LoanOutstandingBalance(orgCode: '101', loanAccountNo: 'L-2023-001', asOnDate: DateTime.now(), principalOutstanding: 15000, interestOutstanding: 1200, penaltyOutstanding: 500, totalOutstanding: 16700, eUser: 'SYS', eDate: DateTime.now()),
    LoanOutstandingBalance(orgCode: '101', loanAccountNo: 'L-2023-002', asOnDate: DateTime.now(), principalOutstanding: 8000, interestOutstanding: 400, penaltyOutstanding: 0, totalOutstanding: 8400, eUser: 'SYS', eDate: DateTime.now()),
    LoanOutstandingBalance(orgCode: '101', loanAccountNo: 'L-2023-003', asOnDate: DateTime.now(), principalOutstanding: 0, interestOutstanding: 0, penaltyOutstanding: 0, totalOutstanding: 0, eUser: 'SYS', eDate: DateTime.now()),
  ];

  final List<LoanRepaymentSchedule> loanRepaymentSchedules = [
    LoanRepaymentSchedule(orgCode: '101', loanAccountNo: 'L-2023-001', installmentNo: 1, dueDate: DateTime(2023, 2, 10), principalDue: 1000, interestDue: 200, totalDue: 1200, principalPaid: 1000, interestPaid: 200, installmentStatus: 'Paid', eUser: 'SYS', eDate: DateTime(2023, 1, 10)),
    LoanRepaymentSchedule(orgCode: '101', loanAccountNo: 'L-2023-001', installmentNo: 2, dueDate: DateTime(2023, 3, 10), principalDue: 1000, interestDue: 180, totalDue: 1180, principalPaid: 500, interestPaid: 180, installmentStatus: 'PartiallyPaid', eUser: 'SYS', eDate: DateTime(2023, 1, 10)),
    LoanRepaymentSchedule(orgCode: '101', loanAccountNo: 'L-2023-001', installmentNo: 3, dueDate: DateTime(2023, 4, 10), principalDue: 1000, interestDue: 160, totalDue: 1160, principalPaid: 0, interestPaid: 0, installmentStatus: 'Overdue', eUser: 'SYS', eDate: DateTime(2023, 1, 10)),
  ];

  final List<ClientGroupMaster> clientGroups = [
    ClientGroupMaster(
      orgCode: '101',
      groupCode: 'JLG-CHENNAI-01',
      groupName: 'Chennai Self Help Group 1',
      branchCode: 'BRN-CH01',
      regionCode: 'REG-SOUTH',
      regionalOfficerId: 'RO-102',
      sourceSystem: 'MANUAL',
      meetingDay: 'Monday',
      meetingFrequency: 'Weekly',
      groupStatus: 'A',
    ),
  ];

  final List<ClientGroupMemberMap> clientGroupMemberMaps = [
    ClientGroupMemberMap(orgCode: '101', groupCode: 'JLG-CHENNAI-01', clientId: 'CLI-001', memberRole: 'Leader', joinDate: DateTime(2026, 01, 10), memberStatus: 'A'),
    ClientGroupMemberMap(orgCode: '101', groupCode: 'JLG-CHENNAI-01', clientId: 'CLI-002', memberRole: 'Member', joinDate: DateTime(2026, 01, 10), memberStatus: 'A'),
    ClientGroupMemberMap(orgCode: '101', groupCode: 'JLG-CHENNAI-01', clientId: 'CLI-003', memberRole: 'Member', joinDate: DateTime(2026, 01, 15), memberStatus: 'A'),
  ];

  // --- Initial Data ---
  final List<RegionMaster> regions = [
    RegionMaster(orgCode: 'ORG01', regionCode: 'REG-NORTH', regionName: 'North India Region', state: 'New Delhi', zone: 'North Zone', status: true),
    RegionMaster(orgCode: 'ORG01', regionCode: 'REG-SOUTH', regionName: 'South India Region', state: 'Tamil Nadu', zone: 'South Zone', status: true),
    RegionMaster(orgCode: 'ORG01', regionCode: 'REG-EAST', regionName: 'East India Region', state: 'West Bengal', zone: 'East Zone', status: true),
    RegionMaster(orgCode: 'ORG01', regionCode: 'REG-WEST', regionName: 'West India Region', state: 'Maharashtra', zone: 'West Zone', status: true),
    RegionMaster(orgCode: 'ORG01', regionCode: 'REG-CENTRAL', regionName: 'Central India Region', state: 'Madhya Pradesh', zone: 'Central Zone', status: false),
  ];

  final List<BranchRegionMap> branchMaps = [
    BranchRegionMap(orgCode: 'ORG01', branchCode: 'BRN-DL01', regionCode: 'REG-NORTH', status: true),
    BranchRegionMap(orgCode: 'ORG01', branchCode: 'BRN-CH01', regionCode: 'REG-SOUTH', status: true),
    BranchRegionMap(orgCode: 'ORG01', branchCode: 'BRN-KK01', regionCode: 'REG-EAST', status: true),
    BranchRegionMap(orgCode: 'ORG01', branchCode: 'BRN-MB01', regionCode: 'REG-WEST', status: true),
    BranchRegionMap(orgCode: 'ORG01', branchCode: 'BRN-BP01', regionCode: 'REG-CENTRAL', status: false),
  ];

  final List<LoanProductMaster> loanProducts = [
    LoanProductMaster(
      orgCode: 'ORG01',
      productCode: 'DISBQUEUE',
      productName: 'Joint Liability Group Loan',
      minAmount: 10000.0,
      maxAmount: 50000.0,
      interestRate: 18.0,
      interestType: 'Reducing',
      rateType: 'Fixed',
      benchmarkRateCode: 'BASE-RATE',
      minTenureMonths: 12,
      maxTenureMonths: 24,
      repayFrequency: 'Monthly',
      prinGl: 'GL-100201',
      intGl: 'GL-300401',
      penalGl: 'GL-300450',
      productStatus: true,
    ),
    LoanProductMaster(
      orgCode: 'ORG01',
      productCode: 'PROD-SHG',
      productName: 'Self Help Group Loan',
      minAmount: 20000.0,
      maxAmount: 100000.0,
      interestRate: 16.5,
      interestType: 'Reducing',
      rateType: 'Fixed',
      benchmarkRateCode: 'BASE-RATE',
      minTenureMonths: 12,
      maxTenureMonths: 36,
      repayFrequency: 'Monthly',
      prinGl: 'GL-100202',
      intGl: 'GL-300402',
      penalGl: 'GL-300451',
      productStatus: true,
    ),
    LoanProductMaster(
      orgCode: 'ORG01',
      productCode: 'PROD-AGRI',
      productName: 'Micro Agriculture Loan',
      minAmount: 15000.0,
      maxAmount: 75000.0,
      interestRate: 14.0,
      interestType: 'Flat',
      rateType: 'Floating',
      benchmarkRateCode: 'MCLR-6M',
      minTenureMonths: 6,
      maxTenureMonths: 18,
      repayFrequency: 'Monthly',
      prinGl: 'GL-100203',
      intGl: 'GL-300403',
      penalGl: 'GL-300452',
      productStatus: true,
    ),
    LoanProductMaster(
      orgCode: 'ORG01',
      productCode: 'PROD-INDIV',
      productName: 'Individual Micro Business Loan',
      minAmount: 50000.0,
      maxAmount: 200000.0,
      interestRate: 20.0,
      interestType: 'Reducing',
      rateType: 'Fixed',
      benchmarkRateCode: 'BASE-RATE',
      minTenureMonths: 12,
      maxTenureMonths: 48,
      repayFrequency: 'Monthly',
      prinGl: 'GL-100204',
      intGl: 'GL-300404',
      penalGl: 'GL-300453',
      productStatus: false,
    ),
  ];

  final List<DelinquencyBucketMaster> delinquencyBuckets = [
    DelinquencyBucketMaster(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-STD', bucketLabel: 'Standard (0-30 days)', overdueDaysFrom: 0, overdueDaysTo: 30, stageOrder: 1, isNpaFlag: false, provisionPct: 0.25, bucketStatus: true),
    DelinquencyBucketMaster(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-SUBSTD', bucketLabel: 'Sub-Standard (31-60 days)', overdueDaysFrom: 31, overdueDaysTo: 60, stageOrder: 2, isNpaFlag: false, provisionPct: 10.0, bucketStatus: true),
    DelinquencyBucketMaster(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-DOUBT', bucketLabel: 'Doubtful (61-90 days)', overdueDaysFrom: 61, overdueDaysTo: 90, stageOrder: 3, isNpaFlag: true, provisionPct: 25.0, bucketStatus: true),
    DelinquencyBucketMaster(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-LOSS', bucketLabel: 'Loss (90+ days)', overdueDaysFrom: 91, overdueDaysTo: 9999, stageOrder: 4, isNpaFlag: true, provisionPct: 100.0, bucketStatus: true),
  ];

  final List<PenaltyRateHistory> penaltyRates = [
    PenaltyRateHistory(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-STD', effDate: DateTime(2026, 01, 01), penaltyType: 'Percentage', penaltyValue: 1.0, rateStatus: true),
    PenaltyRateHistory(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-SUBSTD', effDate: DateTime(2026, 01, 01), penaltyType: 'Percentage', penaltyValue: 2.0, rateStatus: true),
    PenaltyRateHistory(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-DOUBT', effDate: DateTime(2026, 01, 01), penaltyType: 'Percentage', penaltyValue: 3.5, rateStatus: true),
    PenaltyRateHistory(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-LOSS', effDate: DateTime(2026, 01, 01), penaltyType: 'Fixed', penaltyValue: 500.0, rateStatus: true),
  ];

  final List<AssetClassificationGlMap> assetGlMaps = [
    AssetClassificationGlMap(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-STD', prinGl: 'GL-100201-STD', intGl: 'GL-300401-STD', provisionGl: 'GL-200501-STD', mapStatus: true),
    AssetClassificationGlMap(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-SUBSTD', prinGl: 'GL-100201-SUB', intGl: 'GL-300401-SUB', provisionGl: 'GL-200501-SUB', mapStatus: true),
    AssetClassificationGlMap(orgCode: 'ORG01', productCode: 'DISBQUEUE', delinquencyCode: 'JLG-DOUBT', prinGl: 'GL-100201-DBT', intGl: 'GL-300401-DBT', provisionGl: 'GL-200501-DBT', mapStatus: true),
  ];

  final List<PrepaymentForeclosureConfig> prepaymentConfigs = [
    PrepaymentForeclosureConfig(
      orgCode: 'ORG01',
      productCode: 'DISBQUEUE',
      lockInPeriodMonths: 3,
      prepaymentPenaltyType: 'Percentage',
      prepaymentPenaltyValue: 2.0,
      foreclosureFeeType: 'Percentage',
      foreclosureFeeValue: 3.0,
      scheduleRecalcMethod: 'Re-amortization',
      configStatus: true,
    ),
    PrepaymentForeclosureConfig(
      orgCode: 'ORG01',
      productCode: 'PROD-SHG',
      lockInPeriodMonths: 6,
      prepaymentPenaltyType: 'Percentage',
      prepaymentPenaltyValue: 1.5,
      foreclosureFeeType: 'Fixed',
      foreclosureFeeValue: 1000.0,
      scheduleRecalcMethod: 'Tenure Reduction',
      configStatus: true,
    ),
  ];

  final List<RateRevisionHistory> rateRevisions = [
    RateRevisionHistory(orgCode: 'ORG01', productCode: 'PROD-AGRI', effDate: DateTime(2026, 01, 15), revisedRate: 14.5, benchmarkRateCode: 'MCLR-6M', spreadPct: 2.5, revisionReason: 'MCLR revision by RBI', revisionStatus: true),
    RateRevisionHistory(orgCode: 'ORG01', productCode: 'PROD-AGRI', effDate: DateTime(2026, 06, 01), revisedRate: 14.0, benchmarkRateCode: 'MCLR-6M', spreadPct: 2.0, revisionReason: 'Market adjustment', revisionStatus: true),
  ];

  final List<HolidayCalendar> holidays = [
    HolidayCalendar(orgCode: 'ORG01', branchCode: 'ALL', holidayDate: DateTime(2026, 01, 26), holidayName: 'Republic Day', holidayType: 'National', dueDateShiftRule: 'Shift Next', calendarStatus: true),
    HolidayCalendar(orgCode: 'ORG01', branchCode: 'ALL', holidayDate: DateTime(2026, 08, 15), holidayName: 'Independence Day', holidayType: 'National', dueDateShiftRule: 'Shift Next', calendarStatus: true),
    HolidayCalendar(orgCode: 'ORG01', branchCode: 'ALL', holidayDate: DateTime(2026, 10, 02), holidayName: 'Gandhi Jayanti', holidayType: 'National', dueDateShiftRule: 'Shift Next', calendarStatus: true),
    HolidayCalendar(orgCode: 'ORG01', branchCode: 'BRN-CH01', holidayDate: DateTime(2026, 01, 14), holidayName: 'Pongal', holidayType: 'Regional', dueDateShiftRule: 'Shift Prev', calendarStatus: true),
  ];

  final List<Auth101Config> authConfigs = [
    const Auth101Config(id: 'DISBQUEUE', name: 'JLG Product Setup', approvalReq: true, isTran: false, levels: 1),
    const Auth101Config(id: 'REGION-MST', name: 'Region Master', approvalReq: true, isTran: false, levels: 1),
  ];

  final List<AuthRecord> authQueue = [
    AuthRecord(
      orgCode: 'ORG01',
      effDate: '2026-07-13',
      programId: 'DISBQUEUE',
      primaryKey: 'JLG-NEW',
      authSl: 'AUTH-2026-001',
      displayRemarks: 'New Joint Liability Group Product',
      eUser: 'admin',
      eDate: '2026-07-13',
      dataBlocks: [
        AuthDataBlock(recSl: 1, tableName: 'LOAN_PROD', data: {'productCode': 'DISBQUEUE', 'productName': 'JLG Loan'})
      ],
    ),
    AuthRecord(
      orgCode: 'ORG01',
      effDate: '2026-07-13',
      programId: 'REGION-MST',
      primaryKey: 'REG-EAST',
      authSl: 'AUTH-2026-002',
      displayRemarks: 'Create East Region',
      eUser: 'admin',
      eDate: '2026-07-13',
      dataBlocks: [
        AuthDataBlock(recSl: 1, tableName: 'REGION_MST', data: {'regionCode': 'REG-EAST', 'regionName': 'East Region'})
      ],
    ),
  ];

  final List<DisbursalQueue> disbursalQueue = [
    DisbursalQueue(
      orgCode: '101',
      queueId: 'Q-001',
      sourceSystem: 'LOS',
      sourceRefNo: 'APP-100201',
      clientId: 'CLI-001',
      groupCode: 'GRP-001',
      productCode: 'DISBQUEUE',
      approvedAmount: 45000.0,
      approvedTenureMonths: 24,
      approvedInterestRate: 18.0,
      queuedDate: DateTime(2026, 07, 15),
      assignedToUserId: 'admin',
      disbursementStatus: 'Approved',
    ),
    DisbursalQueue(
      orgCode: '101',
      queueId: 'Q-002',
      sourceSystem: 'MANUAL',
      sourceRefNo: null,
      clientId: 'CLI-002',
      groupCode: null,
      productCode: 'PROD-SHG',
      approvedAmount: 80000.0,
      approvedTenureMonths: 36,
      approvedInterestRate: 16.5,
      queuedDate: DateTime(2026, 07, 18),
      assignedToUserId: 'admin',
      disbursementStatus: 'Pending Input',
    ),
  ];

  final List<PendingDisbursal> pendingDisbursals = [
    PendingDisbursal(
      orgCode: '101',
      loanAccountNo: 'L-CLI-002',
      disbursementSeqNo: 1,
      disbursementAmount: 80000.0,
      currencyCode: 'INR',
      disbursementMode: 'Bank',
      bankRefNo: '',
      disbursedByUserId: 'admin',
      disbursementDate: DateTime(2026, 07, 18),
      disbursementStatus: 'Pending Input',
      accPostingRef: '',
      accPostingStatus: 'Pending',
    ),
  ];


  void processAuth(String authSl, String action) {
    final idx = authQueue.indexWhere((element) => element.authSl == authSl);
    if (idx != -1) {
      final record = authQueue[idx];
      if (record.programId == 'DISB002') {
        if (action == '1') {
          // Approved
          final pIdx = pendingDisbursals.indexWhere((p) => p.loanAccountNo == record.primaryKey);
          if (pIdx != -1) {
            pendingDisbursals[pIdx] = pendingDisbursals[pIdx].copyWith(
              disbursementStatus: 'Completed',
              accPostingStatus: 'Posted',
              accPostingRef: 'VOUCH-${DateTime.now().millisecondsSinceEpoch}',
            );
          }
          final clientId = record.primaryKey.replaceFirst('L-', '');
          final qIdx = disbursalQueue.indexWhere((q) => q.clientId == clientId);
          if (qIdx != -1) {
            disbursalQueue[qIdx] = disbursalQueue[qIdx].copyWith(disbursementStatus: 'Approved');
          }
        } else {
          // Rejected
          final pIdx = pendingDisbursals.indexWhere((p) => p.loanAccountNo == record.primaryKey);
          if (pIdx != -1) {
            pendingDisbursals[pIdx] = pendingDisbursals[pIdx].copyWith(
              disbursementStatus: 'Failed',
              accPostingStatus: 'Failed',
            );
          }
          final clientId = record.primaryKey.replaceFirst('L-', '');
          final qIdx = disbursalQueue.indexWhere((q) => q.clientId == clientId);
          if (qIdx != -1) {
            disbursalQueue[qIdx] = disbursalQueue[qIdx].copyWith(disbursementStatus: 'Rejected');
          }
        }
      }
      authQueue.removeAt(idx);
    }
    notifyListeners();
  }


  void removeAuth(String authSl) {
    authQueue.removeWhere((element) => element.authSl == authSl);
    notifyListeners();
  }


  // --- CRUD Methods: Region Master ---
  void addRegion(RegionMaster record) {
    regions.add(record);
    notifyListeners();
  }

  void updateRegion(RegionMaster record) {
    final idx = regions.indexWhere((r) => r.regionCode == record.regionCode);
    if (idx != -1) {
      regions[idx] = record;
      notifyListeners();
    }
  }

  void deleteRegion(String regionCode) {
    regions.removeWhere((r) => r.regionCode == regionCode);
    notifyListeners();
  }

  // --- CRUD Methods: Branch Region Map ---
  void addBranchMap(BranchRegionMap record) {
    branchMaps.add(record);
    notifyListeners();
  }

  void updateBranchMap(BranchRegionMap record) {
    final idx = branchMaps.indexWhere((b) => b.branchCode == record.branchCode);
    if (idx != -1) {
      branchMaps[idx] = record;
      notifyListeners();
    }
  }

  void deleteBranchMap(String branchCode) {
    branchMaps.removeWhere((b) => b.branchCode == branchCode);
    notifyListeners();
  }

  // --- CRUD Methods: Loan Product Master ---
  void addLoanProduct(LoanProductMaster record) {
    loanProducts.add(record);
    notifyListeners();
  }

  void updateLoanProduct(LoanProductMaster record) {
    final idx = loanProducts.indexWhere((l) => l.productCode == record.productCode);
    if (idx != -1) {
      loanProducts[idx] = record;
      notifyListeners();
    }
  }

  void deleteLoanProduct(String productCode) {
    loanProducts.removeWhere((l) => l.productCode == productCode);
    notifyListeners();
  }

  // --- CRUD Methods: Delinquency Bucket Master ---
  void addDelinquencyBucket(DelinquencyBucketMaster record) {
    delinquencyBuckets.add(record);
    notifyListeners();
  }

  void updateDelinquencyBucket(DelinquencyBucketMaster record) {
    final idx = delinquencyBuckets.indexWhere((d) => d.delinquencyCode == record.delinquencyCode);
    if (idx != -1) {
      delinquencyBuckets[idx] = record;
      notifyListeners();
    }
  }

  void deleteDelinquencyBucket(String delinquencyCode) {
    delinquencyBuckets.removeWhere((d) => d.delinquencyCode == delinquencyCode);
    notifyListeners();
  }

  // --- CRUD Methods: Penalty Rate History ---
  void addPenaltyRate(PenaltyRateHistory record) {
    penaltyRates.add(record);
    notifyListeners();
  }

  void updatePenaltyRate(PenaltyRateHistory record) {
    final idx = penaltyRates.indexWhere((p) => p.productCode == record.productCode && p.delinquencyCode == record.delinquencyCode && p.effDate == record.effDate);
    if (idx != -1) {
      penaltyRates[idx] = record;
      notifyListeners();
    }
  }

  void deletePenaltyRate(String productCode, String delinquencyCode, DateTime effDate) {
    penaltyRates.removeWhere((p) => p.productCode == productCode && p.delinquencyCode == delinquencyCode && p.effDate == effDate);
    notifyListeners();
  }

  // --- CRUD Methods: Asset Classification GL Map ---
  void addAssetGlMap(AssetClassificationGlMap record) {
    assetGlMaps.add(record);
    notifyListeners();
  }

  void updateAssetGlMap(AssetClassificationGlMap record) {
    final idx = assetGlMaps.indexWhere((a) => a.productCode == record.productCode && a.delinquencyCode == record.delinquencyCode);
    if (idx != -1) {
      assetGlMaps[idx] = record;
      notifyListeners();
    }
  }

  void deleteAssetGlMap(String productCode, String delinquencyCode) {
    assetGlMaps.removeWhere((a) => a.productCode == productCode && a.delinquencyCode == delinquencyCode);
    notifyListeners();
  }

  // --- CRUD Methods: Prepayment Foreclosure Config ---
  void addPrepaymentConfig(PrepaymentForeclosureConfig record) {
    prepaymentConfigs.add(record);
    notifyListeners();
  }

  void updatePrepaymentConfig(PrepaymentForeclosureConfig record) {
    final idx = prepaymentConfigs.indexWhere((p) => p.productCode == record.productCode);
    if (idx != -1) {
      prepaymentConfigs[idx] = record;
      notifyListeners();
    }
  }

  void deletePrepaymentConfig(String productCode) {
    prepaymentConfigs.removeWhere((p) => p.productCode == productCode);
    notifyListeners();
  }

  // --- CRUD Methods: Rate Revision History ---
  void addRateRevision(RateRevisionHistory record) {
    rateRevisions.add(record);
    notifyListeners();
  }

  void updateRateRevision(RateRevisionHistory record) {
    final idx = rateRevisions.indexWhere((r) => r.productCode == record.productCode && r.effDate == record.effDate);
    if (idx != -1) {
      rateRevisions[idx] = record;
      notifyListeners();
    }
  }

  void deleteRateRevision(String productCode, DateTime effDate) {
    rateRevisions.removeWhere((r) => r.productCode == productCode && r.effDate == effDate);
    notifyListeners();
  }

  // --- CRUD Methods: Holiday Calendar ---
  void addHoliday(HolidayCalendar record) {
    holidays.add(record);
    notifyListeners();
  }

  void updateHoliday(HolidayCalendar record) {
    final idx = holidays.indexWhere((h) => h.branchCode == record.branchCode && h.holidayDate == record.holidayDate);
    if (idx != -1) {
      holidays[idx] = record;
      notifyListeners();
    }
  }

  void deleteHoliday(String branchCode, DateTime holidayDate) {
    holidays.removeWhere((h) => h.branchCode == branchCode && h.holidayDate == holidayDate);
    notifyListeners();
  }

  // --- CRUD Methods: Disbursal Queue (DISB001) & Disbursement Queue (DISB002) ---
  void addDisbursalQueue(DisbursalQueue record) {
    disbursalQueue.add(record);
    // Automatically create a corresponding PendingDisbursal record
    pendingDisbursals.add(PendingDisbursal(
      orgCode: record.orgCode,
      loanAccountNo: 'L-${record.clientId}',
      disbursementSeqNo: 1,
      disbursementAmount: record.approvedAmount,
      currencyCode: 'INR',
      disbursementMode: 'Bank',
      bankRefNo: '',
      disbursedByUserId: record.assignedToUserId ?? 'admin',
      disbursementDate: DateTime.now(),
      disbursementStatus: 'Pending Input',
      accPostingRef: '',
      accPostingStatus: 'Pending',
    ));
    notifyListeners();
  }

  void updateDisbursalQueue(DisbursalQueue record) {
    final idx = disbursalQueue.indexWhere((r) => r.queueId == record.queueId);
    if (idx != -1) {
      disbursalQueue[idx] = record;
      notifyListeners();
    }
  }

  void deleteDisbursalQueue(String queueId) {
    final recordIdx = disbursalQueue.indexWhere((r) => r.queueId == queueId);
    if (recordIdx != -1) {
      final record = disbursalQueue[recordIdx];
      disbursalQueue.removeAt(recordIdx);
      pendingDisbursals.removeWhere((p) => p.loanAccountNo == 'L-${record.clientId}');
      notifyListeners();
    }
  }

  void submitToAuthQueue(String loanAccountNo, PendingDisbursal updatedRecord, DisbursalQueue updatedQueue) {
    // 1. Update DisbursalQueue
    final qIdx = disbursalQueue.indexWhere((q) => q.clientId == updatedQueue.clientId);
    if (qIdx != -1) {
      disbursalQueue[qIdx] = updatedQueue.copyWith(disbursementStatus: 'Pending Authorization');
    }
    
    // 2. Update PendingDisbursal
    final pIdx = pendingDisbursals.indexWhere((p) => p.loanAccountNo == loanAccountNo);
    if (pIdx != -1) {
      pendingDisbursals[pIdx] = updatedRecord.copyWith(disbursementStatus: 'Pending Authorization');
    }

    // 3. Add to AuthQueue
    authQueue.add(AuthRecord(
      orgCode: updatedRecord.orgCode,
      effDate: DateTime.now().toIso8601String().substring(0, 10),
      programId: 'DISB002',
      primaryKey: loanAccountNo,
      authSl: 'AUTH-DISB-${DateTime.now().millisecondsSinceEpoch}',
      displayRemarks: 'Authorize Disbursal for Client ${updatedQueue.clientId}',
      eUser: 'admin',
      eDate: DateTime.now().toIso8601String().substring(0, 10),
      dataBlocks: [
        AuthDataBlock(
          recSl: 1,
          tableName: 'DISB_DTL',
          data: {
            'Loan Account No': updatedRecord.loanAccountNo,
            'Disbursement Amount': '${updatedRecord.currencyCode} ${updatedRecord.disbursementAmount.toStringAsFixed(2)}',
            'Mode': updatedRecord.disbursementMode,
            'Bank Ref No': updatedRecord.bankRefNo ?? '',
            'Product Code': updatedQueue.productCode,
            'Approved Tenure': '${updatedQueue.approvedTenureMonths} Months',
            'Interest Rate': '${updatedQueue.approvedInterestRate}%',
          },
        ),
      ],
    ));
    
    notifyListeners();
  }

  void approvePendingDisbursal(String loanAccountNo) {
    final pIdx = pendingDisbursals.indexWhere((p) => p.loanAccountNo == loanAccountNo);
    if (pIdx != -1) {
      pendingDisbursals[pIdx] = pendingDisbursals[pIdx].copyWith(
        disbursementStatus: 'Completed',
        accPostingStatus: 'Posted',
        accPostingRef: 'VOUCH-${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Update status in disbursalQueue to Approved
      final clientId = loanAccountNo.replaceFirst('L-', '');
      final qIdx = disbursalQueue.indexWhere((q) => q.clientId == clientId);
      if (qIdx != -1) {
        disbursalQueue[qIdx] = disbursalQueue[qIdx].copyWith(disbursementStatus: 'Approved');
      }
      notifyListeners();
    }
  }

  void rejectPendingDisbursal(String loanAccountNo) {
    final pIdx = pendingDisbursals.indexWhere((p) => p.loanAccountNo == loanAccountNo);
    if (pIdx != -1) {
      pendingDisbursals[pIdx] = pendingDisbursals[pIdx].copyWith(
        disbursementStatus: 'Failed',
        accPostingStatus: 'Failed',
      );
      
      // Update status in disbursalQueue to Rejected
      final clientId = loanAccountNo.replaceFirst('L-', '');
      final qIdx = disbursalQueue.indexWhere((q) => q.clientId == clientId);
      if (qIdx != -1) {
        disbursalQueue[qIdx] = disbursalQueue[qIdx].copyWith(disbursementStatus: 'Rejected');
      }
      notifyListeners();
    }
  }
  // --- CRUD Methods: Client Group Master ---
  void addClientGroup(ClientGroupMaster record) {
    clientGroups.add(record);
    notifyListeners();
  }

  void updateClientGroup(ClientGroupMaster record) {
    final idx = clientGroups.indexWhere((c) => c.groupCode == record.groupCode);
    if (idx != -1) {
      clientGroups[idx] = record;
      notifyListeners();
    }
  }

  void addLoanAccount(LoanAccountMaster record) {
    loanAccounts.add(record);
    notifyListeners();
  }

  void updateLoanAccount(LoanAccountMaster record) {
    final idx = loanAccounts.indexWhere((c) => c.loanAccountNo == record.loanAccountNo);
    if (idx != -1) {
      loanAccounts[idx] = record;
      notifyListeners();
    }
  }

  void deleteLoanAccount(String accountNo) {
    loanAccounts.removeWhere((c) => c.loanAccountNo == accountNo);
    notifyListeners();
  }

  void deleteClientGroup(String groupCode) {
    clientGroups.removeWhere((c) => c.groupCode == groupCode);
    notifyListeners();
  }

  // --- CRUD Methods: Client Group Member Map ---
  void addClientGroupMemberMap(ClientGroupMemberMap record) {
    clientGroupMemberMaps.add(record);
    notifyListeners();
  }

  void updateClientGroupMemberMap(ClientGroupMemberMap record) {
    final idx = clientGroupMemberMaps.indexWhere((c) => c.groupCode == record.groupCode && c.clientId == record.clientId);
    if (idx != -1) {
      clientGroupMemberMaps[idx] = record;
      notifyListeners();
    }
  }

  void deleteClientGroupMemberMap(String groupCode, String clientId) {
    clientGroupMemberMaps.removeWhere((c) => c.groupCode == groupCode && c.clientId == clientId);
    notifyListeners();
  }
}