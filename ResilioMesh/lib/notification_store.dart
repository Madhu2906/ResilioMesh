import 'package:flutter/material.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationStore extends ChangeNotifier {
  static final NotificationStore instance = NotificationStore._internal();
  factory NotificationStore() => instance;
  NotificationStore._internal();

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  // Getter to get only unread count for badge display
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(String title, String body) {
    _notifications.insert(
      0,
      AppNotification(
        title: title,
        body: body,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
    notifyListeners();
  }

  // Marks all notifications as read when the user opens the Notifications screen
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  // Clears all notifications completely
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}