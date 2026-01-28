import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DateRangeSelector extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeChanged;
  final VoidCallback? onCustomDatePicker;

  const DateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    this.onCustomDatePicker,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(context, '7d', '7 Days'),
          const SizedBox(width: 8),
          _buildChip(context, '30d', '30 Days'),
          const SizedBox(width: 8),
          _buildChip(context, '90d', '90 Days'),
          if (onCustomDatePicker != null) ...[
            const SizedBox(width: 8),
            _buildCustomButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String value, String label) {
    final isSelected = selectedRange == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onRangeChanged(value),
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onCustomDatePicker,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: const Text('Custom'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
