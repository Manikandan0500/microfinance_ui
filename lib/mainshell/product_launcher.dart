import 'package:flutter/material.dart';

class ProductLauncher {
  static OverlayEntry createOverlayEntry({
    required Offset offset,
    required Size size,
    required VoidCallback onClose,
  }) {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible layer to dismiss the popup when clicking outside
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 10,
            left: offset.dx,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildLauncherItem('ACCESS\nMANAGER', Icons.admin_panel_settings, isSelected: true),
                    _buildLauncherItem('CONNECT', Icons.chat_bubble_outline),
                    _buildLauncherItem('HRM', Icons.people_outline),
                    _buildLauncherItem('CRM', Icons.support_agent),
                    _buildLauncherItem('PAYROLL', Icons.account_balance_wallet_outlined),
                    _buildLauncherItem('PROJECT', Icons.assignment_outlined),
                    _buildLauncherItem('TEST', Icons.settings_suggest_outlined),
                    _buildLauncherItem('TICKET', Icons.confirmation_number_outlined),
                    _buildLauncherItem('EMAIL', Icons.email_outlined),
                    _buildLauncherItem('FIXED ASSET', Icons.real_estate_agent_outlined),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLauncherItem(String title, IconData icon, {bool isSelected = false}) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade50,
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
