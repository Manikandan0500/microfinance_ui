import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Total Records Card ---
class TotalRecordsCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const TotalRecordsCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3050),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Custom Program Input Field ---
class ProgramFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool isRequired;
  final bool isLocked;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const ProgramFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.prefixIcon,
    this.isRequired = false,
    this.isLocked = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: !isLocked,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator ?? (isRequired ? (val) => val == null || val.isEmpty ? 'Required field' : null : null),
        style: TextStyle(
          color: isLocked ? Colors.grey.shade700 : const Color(0xFF1E3050),
          fontWeight: isLocked ? FontWeight.w500 : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(
            color: isLocked ? Colors.grey.shade500 : const Color(0xFF0288D1),
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF0288D1), size: 20),
          suffixIcon: isLocked ? const Icon(Icons.lock_outline, color: Colors.grey, size: 18) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// --- Custom Program Dropdown Field ---
class ProgramDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData prefixIcon;
  final bool isRequired;
  final bool isLocked;
  final void Function(String?)? onChanged;

  const ProgramDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.prefixIcon,
    this.isRequired = false,
    this.isLocked = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        onChanged: isLocked ? null : onChanged,
        validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required field' : null : null,
        style: TextStyle(
          color: isLocked ? Colors.grey.shade700 : const Color(0xFF1E3050),
        ),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(
            color: isLocked ? Colors.grey.shade500 : const Color(0xFF0288D1),
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF0288D1), size: 20),
          suffixIcon: isLocked ? const Icon(Icons.lock_outline, color: Colors.grey, size: 18) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
      ),
    );
  }
}

// --- Custom Program Date Field ---
class ProgramDateField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final IconData prefixIcon;
  final bool isRequired;
  final bool isLocked;
  final void Function(DateTime)? onDateSelected;

  const ProgramDateField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.prefixIcon,
    this.isRequired = false,
    this.isLocked = false,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = selectedDate != null ? DateFormat('dd-MM-yyyy').format(selectedDate!) : '';
    final controller = TextEditingController(text: displayValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enabled: !isLocked,
        validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required field' : null : null,
        onTap: isLocked
            ? null
            : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                );
                if (date != null && onDateSelected != null) {
                  onDateSelected!(date);
                }
              },
        style: TextStyle(
          color: isLocked ? Colors.grey.shade700 : const Color(0xFF1E3050),
        ),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(
            color: isLocked ? Colors.grey.shade500 : const Color(0xFF0288D1),
            fontSize: 14,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF0288D1), size: 20),
          suffixIcon: isLocked
              ? const Icon(Icons.lock_outline, color: Colors.grey, size: 18)
              : const Icon(Icons.calendar_today, color: Color(0xFF0288D1), size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// --- Program Status Toggle ---
class ProgramStatusToggle extends StatelessWidget {
  final bool value;
  final bool isLocked;
  final ValueChanged<bool>? onChanged;

  const ProgramStatusToggle({
    super.key,
    required this.value,
    this.isLocked = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked ? Colors.grey.shade300 : Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Status *',
                style: TextStyle(
                  color: Color(0xFF0288D1),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: value ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: isLocked ? null : onChanged,
            activeColor: Colors.green,
            activeTrackColor: Colors.green.shade100,
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

// --- Locked Notice Bar ---
class YellowNoticeBar extends StatelessWidget {
  const YellowNoticeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFF59D), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            'Locked fields cannot be modified',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Red Delete Banner ---
class RedDeleteBanner extends StatelessWidget {
  const RedDeleteBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                'Delete Confirmation',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to delete this record? This action cannot be undone.',
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Delete Confirmation Disclaimer Checkbox ---
class DeleteConfirmationBox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const DeleteConfirmationBox({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I understand this will permanently delete this record and all related data.',
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Standard Action Button ---
class StandardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const StandardButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red.shade700 : const Color(0xFF0288D1),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red.shade700 : const Color(0xFF0288D1),
            side: BorderSide(
              color: isDestructive ? Colors.red.shade300 : const Color(0xFF0288D1),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    return isPrimary
        ? ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          );
  }
}

// --- Action Button for Grid (Eye, Edit, Trash) ---
class ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }
}

// --- Grid Status Pill ---
class StatusPill extends StatelessWidget {
  final bool status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status ? 'Active' : 'Inactive',
            style: TextStyle(
              color: status ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
