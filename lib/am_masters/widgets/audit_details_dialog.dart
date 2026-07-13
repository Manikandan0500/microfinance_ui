import 'package:flutter/material.dart';

const Color _kP = Color(0xFF3D6EBE);
const Color _kText = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSurface = Color(0xFFF8FAFC);
const Color _kG = Color(0xFF16A34A);
const Color _kGL = Color(0xFFDCFCE7);

class AuditDetailsDialog {
  static void show(
    BuildContext context, {
    required String? cuser,
    required dynamic cdate,
    required String? euser,
    required dynamic edate,
    required String? auser,
    required dynamic adate,
    String title = 'Audit Details',
    String subtitle = 'Record identification and audit trail',
    bool showVerifiedBadge = true,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _AuditDialogWidget(
        cuser: cuser,
        cdate: cdate,
        euser: euser,
        edate: edate,
        auser: auser,
        adate: adate,
        title: title,
        subtitle: subtitle,
        showVerifiedBadge: showVerifiedBadge,
      ),
    );
  }
}

class _AuditDialogWidget extends StatelessWidget {
  final String? cuser;
  final dynamic cdate;
  final String? euser;
  final dynamic edate;
  final String? auser;
  final dynamic adate;
  final String title;
  final String subtitle;
  final bool showVerifiedBadge;

  const _AuditDialogWidget({
    required this.cuser,
    required this.cdate,
    required this.euser,
    required this.edate,
    required this.auser,
    required this.adate,
    required this.title,
    required this.subtitle,
    required this.showVerifiedBadge,
  });

  static String _formatAuditDate(dynamic date) {
    if (date == null) return '—';
    if (date is DateTime) {
      return _formatDateTime(date);
    }
    final dateStr = date.toString().trim();
    if (dateStr.isEmpty || dateStr == '—') return '—';
    
    try {
      final parsed = DateTime.parse(dateStr);
      return _formatDateTime(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatDateTime(DateTime d) {
    try {
      final local = d.toLocal();
      const ms = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final m = local.minute.toString().padLeft(2, '0');
      final p = local.hour >= 12 ? 'PM' : 'AM';
      return '${local.day.toString().padLeft(2, '0')} ${ms[local.month - 1]} ${local.year}, ${h.toString().padLeft(2, '0')}:$m $p';
    } catch (_) {
      return d.toString();
    }
  }

  static String _cap(String? s) {
    if (s == null || s.isEmpty || s == '—') return s ?? '—';
    try {
      return s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
    } catch (_) {
      return s;
    }
  }

  Widget _auditItem(String label, String value, IconData icon) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kP, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _kP),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            top: -8,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kP,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 750,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEEF3FB), Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kP,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kP,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showVerifiedBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kGL,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kG,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      _auditItem(
                        'Created By',
                        _cap(cuser),
                        Icons.person_add_alt_1_rounded,
                      ),
                      const SizedBox(width: 24),
                      _auditItem(
                        'Created Date',
                        _formatAuditDate(cdate),
                        Icons.calendar_today_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      _auditItem(
                        'Modified By',
                        _cap(euser),
                        Icons.person_search_rounded,
                      ),
                      const SizedBox(width: 24),
                      _auditItem(
                        'Modified Date',
                        _formatAuditDate(edate),
                        Icons.edit_calendar_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      _auditItem(
                        'Approved By',
                        _cap(auser),
                        Icons.how_to_reg_rounded,
                      ),
                      const SizedBox(width: 24),
                      _auditItem(
                        'Approved Date',
                        _formatAuditDate(adate),
                        Icons.fact_check_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Center(
                child: SizedBox(
                  width: 140,
                  height: 44,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kP, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
