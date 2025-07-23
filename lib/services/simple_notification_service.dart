import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  final Map<int, ReminderInfo> _scheduledReminders = {};

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('✅ NotificationService initialized for web');
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    debugPrint('✅ Notification permissions granted (web mode)');
    return true;
  }

  Future<void> scheduleNoteReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Store reminder info
    _scheduledReminders[id] = ReminderInfo(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );

    debugPrint('📅 Reminder scheduled: $title for ${scheduledDate.toString()}');
    
    // For web, show immediate confirmation
    // In a real app, this would schedule actual notifications
    _showWebNotificationConfirmation(title, scheduledDate);
  }

  Future<void> cancelNotification(int id) async {
    _scheduledReminders.remove(id);
    debugPrint('❌ Reminder cancelled: $id');
  }

  Future<void> cancelAllNotifications() async {
    _scheduledReminders.clear();
    debugPrint('❌ All reminders cancelled');
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('🔔 Immediate notification: $title - $body');
  }

  int generateNotificationId(String noteId) {
    return noteId.hashCode.abs();
  }

  void _showWebNotificationConfirmation(String title, DateTime scheduledDate) {
    final timeUntil = scheduledDate.difference(DateTime.now());
    if (timeUntil.inMinutes > 0) {
      debugPrint('⏰ Web reminder set: "$title" in ${timeUntil.inMinutes} minutes');
    } else {
      debugPrint('⏰ Web reminder set: "$title" for ${scheduledDate.toString()}');
    }
  }
}

class ReminderInfo {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  ReminderInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });
}
