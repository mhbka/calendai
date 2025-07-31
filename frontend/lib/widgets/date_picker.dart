import 'package:flutter/material.dart';

/// A opinionated nullable date picker.
class DatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isNullable;
  final String? nullText;
  final Function(DateTime?) onDateChanged;
  final Color? accentColor;

  const DatePicker({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
    this.isNullable = false,
    this.nullText,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Colors.blue;
    final isSelected = selectedDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.calendar_today : Icons.all_inclusive,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isNullable && isSelected) _buildClearButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (selectedDate != null) {
      return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
    }
    return nullText ?? 'Select date';
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () => onDateChanged(null),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.close,
          size: 16,
          color: Colors.red.shade600,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? (firstDate ?? DateTime.now()),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selected != null) {
      onDateChanged(selected);
    }
  }
}