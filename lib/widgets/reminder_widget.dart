import 'package:flutter/material.dart';
import 'package:youtube_messenger_app/core/theme/app_theme.dart';

class ReminderWidget extends StatelessWidget {
  final DateTime? reminderDate;
  final Function(DateTime?) onReminderChanged;

  const ReminderWidget({
    super.key,
    required this.reminderDate,
    required this.onReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (reminderDate != null) ...[
                // Current reminder display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder set for:',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange[600],
                              ),
                            ),
                            Text(
                              _formatReminderDate(reminderDate!),
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.orange[600]),
                        onPressed: () => onReminderChanged(null),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Quick reminder options
              Text(
                reminderDate == null ? 'Set a reminder:' : 'Change reminder:',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Quick options
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickReminderChip(
                    context,
                    'Later today',
                    _getLaterToday(),
                  ),
                  _buildQuickReminderChip(
                    context,
                    'Tomorrow',
                    _getTomorrow(),
                  ),
                  _buildQuickReminderChip(
                    context,
                    'Next week',
                    _getNextWeek(),
                  ),
                  _buildQuickReminderChip(
                    context,
                    'Custom',
                    null,
                    isCustom: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReminderChip(
    BuildContext context,
    String label,
    DateTime? dateTime, {
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCustom) {
          _showCustomReminderPicker(context);
        } else if (dateTime != null) {
          onReminderChanged(dateTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCustom ? Icons.calendar_today : Icons.access_time,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getLaterToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 18, 0); // 6 PM today
  }

  DateTime _getTomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9, 0); // 9 AM tomorrow
  }

  DateTime _getNextWeek() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 7, 9, 0); // 9 AM next week
  }

  Future<void> _showCustomReminderPicker(BuildContext context) async {
    final now = DateTime.now();
    
    // First pick date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: reminderDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      // Then pick time
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          reminderDate ?? DateTime(now.year, now.month, now.day, 9, 0),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final finalDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        
        onReminderChanged(finalDateTime);
      }
    }
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    String dateStr;
    if (difference.inDays == 0) {
      dateStr = 'Today';
    } else if (difference.inDays == 1) {
      dateStr = 'Tomorrow';
    } else if (difference.inDays < 7) {
      dateStr = '${difference.inDays} days from now';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }
}
