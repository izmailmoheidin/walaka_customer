import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService with ChangeNotifier {
  int _newOrdersCount = 0;
  List<NotificationItem> _notifications = [];
  
  // Audio player for notification sounds
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  // Getters
  int get newOrdersCount => _newOrdersCount;
  List<NotificationItem> get notifications => _notifications;
  bool get hasUnreadNotifications => _notifications.any((notification) => !notification.isRead);
  
  // Initialize
  Future<void> init() async {
    // Initialize any resources needed
    await _audioPlayer.setSource(AssetSource('sounds/notification_sound.mp3'));
  }
  
  // Add a new notification
  void addNotification({
    required String title,
    required String body,
    String? type,
    String? payload,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type ?? 'general',
      payload: payload,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    _notifications.insert(0, notification);
    notifyListeners();
  }
  
  // Add order notification with sound
  Future<void> addOrderNotification({
    required int count,
    String? orderId,
  }) async {
    _newOrdersCount += count;
    
    final title = 'New Order${count > 1 ? 's' : ''}';
    final body = 'You have $count new order${count > 1 ? 's' : ''} waiting for review';
    
    addNotification(
      title: title,
      body: body,
      type: 'order',
      payload: orderId,
    );
    
    // Play notification sound
    await playNotificationSound();
    
    notifyListeners();
  }
  
  // Play notification sound
  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }
  
  // Show in-app notification
  void showInAppNotification(BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
      action: SnackBarAction(
        label: 'VIEW',
        onPressed: () {
          if (onTap != null) {
            onTap();
          }
        },
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 5),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  // Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications.map((notification) => 
      notification.copyWith(isRead: true)).toList();
    notifyListeners();
  }
  
  // Reset new orders count
  void resetNewOrdersCount() {
    _newOrdersCount = 0;
    notifyListeners();
  }
  
  // Remove a notification
  void removeNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
    notifyListeners();
  }
  
  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}

// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? payload;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    required this.timestamp,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? payload,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
