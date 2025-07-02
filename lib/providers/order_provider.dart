import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/store_order.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final NotificationService _notificationService = NotificationService();
  
  int _previousNewOrdersCount = 0;
  String _filterStatus = 'all';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _initialized = false;
  
  // Getters
  List<StoreOrder> get orders => _orderService.orders;
  List<StoreOrder> get pendingOrders => _orderService.pendingOrders;
  List<StoreOrder> get completedOrders => _orderService.completedOrders;
  List<StoreOrder> get canceledOrders => _orderService.canceledOrders;
  bool get isLoading => _orderService.isLoading;
  String? get error => _orderService.error;
  int get newOrdersCount => _notificationService.newOrdersCount;
  List<NotificationItem> get notifications => _notificationService.notifications;
  bool get hasUnreadNotifications => _notificationService.hasUnreadNotifications;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get initialized => _initialized;
  
  // Filtered orders based on current filters
  List<StoreOrder> get filteredOrders {
    List<StoreOrder> result;
    
    // Filter by status
    switch (_filterStatus) {
      case 'pending':
        result = _orderService.pendingOrders;
        break;
      case 'completed':
        result = _orderService.completedOrders;
        break;
      case 'canceled':
        result = _orderService.canceledOrders;
        break;
      case 'all':
      default:
        result = _orderService.orders;
        break;
    }
    
    // Filter by date range
    if (_startDate != null && _endDate != null) {
      result = result.where((StoreOrder order) {
        return order.createdAt.isAfter(_startDate!) && 
               order.createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      result = result.where((StoreOrder order) {
        // Include userPhoneNumber in search if it's available
        final hasPhoneMatch = order.userPhoneNumber != null && 
            order.userPhoneNumber!.toLowerCase().contains(lowercaseQuery);
            
        return order.customerName.toLowerCase().contains(lowercaseQuery) ||
               order.paymentNumber.toLowerCase().contains(lowercaseQuery) ||
               order.gameId.toLowerCase().contains(lowercaseQuery) ||
               order.gameTitle.toLowerCase().contains(lowercaseQuery) ||
               hasPhoneMatch ||
               order.id.toLowerCase().contains(lowercaseQuery);
      }).toList();
      
      debugPrint('Search query "$_searchQuery" matched ${result.length} orders');
    }
    
    return result;
  }
  
  // Initialize
  Future<void> init() async {
    debugPrint('Initializing OrderProvider...');
    
    // Check if Firestore is accessible
    try {
      final testQuery = await FirebaseFirestore.instance.collection('orders').limit(1).get();
      debugPrint('Firestore connection test: ${testQuery.docs.isEmpty ? "No orders found" : "Connection successful"}');
      if (testQuery.docs.isNotEmpty) {
        debugPrint('Sample order ID: ${testQuery.docs.first.id}');
        final data = testQuery.docs.first.data();
        debugPrint('Sample order fields: ${data.keys.join(", ")}');
      }
    } catch (e) {
      debugPrint('Error testing Firestore connection: $e');
    }
    
    _notificationService.init();
    _orderService.init();
    _checkForNewOrders();
    _initialized = true;
    notifyListeners();
    
    // Set up auto-refresh timer
    _setupAutoRefresh();
  }
  
  // Timer for auto-refresh
  Timer? _autoRefreshTimer;
  
  // Set up auto-refresh timer
  void _setupAutoRefresh() {
    // Cancel any existing timer
    _autoRefreshTimer?.cancel();
    
    // Create a new timer that refreshes orders every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('Auto-refreshing orders...');
      silentRefresh();
    });
  }
  
  // Check for new orders and show notifications
  void _checkForNewOrders() {
    debugPrint('Setting up new orders listener...');
    _orderService.addListener(() {
      final currentNewOrdersCount = _orderService.newOrdersCount;
      debugPrint('New orders check: current=$currentNewOrdersCount, previous=$_previousNewOrdersCount');
      
      // If there are new orders since last check
      if (currentNewOrdersCount > _previousNewOrdersCount && _previousNewOrdersCount > 0) {
        final newOrdersCount = currentNewOrdersCount - _previousNewOrdersCount;
        debugPrint('Detected $newOrdersCount new orders');
        _showNewOrderNotification(newOrdersCount);
      }
      
      // Check for changes in order counts
      _checkOrderCountChanges();
      
      _previousNewOrdersCount = currentNewOrdersCount;
    });
  }
  
  // Previous order counts to detect changes
  int _prevPendingCount = 0;
  int _prevCompletedCount = 0;
  int _prevCanceledCount = 0;
  
  // Check for changes in order counts
  void _checkOrderCountChanges() {
    final pendingCount = _orderService.pendingOrders.length;
    final completedCount = _orderService.completedOrders.length;
    final canceledCount = _orderService.canceledOrders.length;
    
    // Only check after initialization
    if (_prevPendingCount > 0) {
      if (pendingCount != _prevPendingCount) {
        debugPrint('Pending orders count changed: $_prevPendingCount -> $pendingCount');
        
        // Show notification if count increased
        if (pendingCount > _prevPendingCount) {
          final newCount = pendingCount - _prevPendingCount;
          _notificationService.addOrderNotification(
            count: newCount,
          );
        }
      }
      
      if (completedCount != _prevCompletedCount) {
        debugPrint('Completed orders count changed: $_prevCompletedCount -> $completedCount');
      }
      
      if (canceledCount != _prevCanceledCount) {
        debugPrint('Canceled orders count changed: $_prevCanceledCount -> $canceledCount');
      }
    }
    
    // Update previous counts
    _prevPendingCount = pendingCount;
    _prevCompletedCount = completedCount;
    _prevCanceledCount = canceledCount;
  }
  
  // Show notification for new orders
  void _showNewOrderNotification(int count) {
    _notificationService.addOrderNotification(
      count: count,
    );
    _playSoundNotification();
  }
  
  // Play sound notification
  void _playSoundNotification() {
    // Add code to play sound notification here
  }
  
  // Show notification in UI
  void showNotificationInUI(BuildContext context, String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(body),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to orders screen or show orders dialog
          },
        ),
      ),
    );
  }
  
  // Mark orders as seen by admin
  Future<void> markOrdersAsSeen() async {
    _orderService.resetNewOrdersCount();
    notifyListeners();
  }

  // Confirm payment for an order
  Future<bool> confirmPayment(String orderId) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final now = DateTime.now();
      
      await orderRef.update({
        'paymentStatus': 'completed',
        'paymentCompletedAt': Timestamp.fromDate(now),
        'status': 'completed',
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Refresh orders to update the UI
      await refreshOrders();
      return true;
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      return false;
    }
  }
  
  // Reject payment for an order
  Future<bool> rejectPayment(String orderId, String reason) async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final now = DateTime.now();
      
      await orderRef.update({
        'paymentStatus': 'failed',
        'status': 'canceled',
        'rejectionReason': reason,
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Refresh orders to update the UI
      await refreshOrders();
      return true;
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      return false;
    }
  }
  
  // Set filter status
  void setFilterStatus(String status) {
    if (_filterStatus != status) {
      _filterStatus = status;
      notifyListeners();
    }
  }

  // Set search query and notify listeners
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      debugPrint('Search query set to: "$query"');
      notifyListeners();
    }
  }
  
  // Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  
  // Clear all filters
  void clearFilters() {
    _filterStatus = 'all';
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
  
  // Update order to any status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final result = await _orderService.updateOrderStatus(orderId, newStatus);
    notifyListeners();
    return result;
  }
  
  // Complete an order
  Future<bool> completeOrder(String orderId) async {
    final result = await _orderService.completeOrder(orderId);
    notifyListeners();
    return result;
  }
  
  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    final result = await _orderService.cancelOrder(orderId);
    notifyListeners();
    return result;
  }
  
  // Set order to pending
  Future<bool> setPendingOrder(String orderId) async {
    final result = await _orderService.setPendingOrder(orderId);
    notifyListeners();
    return result;
  }
  
  // Get total sales
  double getTotalSales() {
    return _orderService.getTotalSales();
  }
  
  // Get total sales for current date range
  double getTotalSalesForCurrentDateRange() {
    if (_startDate != null && _endDate != null) {
      return _orderService.getTotalSalesForDateRange(_startDate!, _endDate!);
    }
    return 0.0;
  }
  
  // Create a test order (for debugging only)
  Future<void> createTestOrder() async {
    debugPrint('Creating test order...');
    await _orderService.createTestOrder();
    notifyListeners();
  }
  
  // Force refresh orders
  Future<void> refreshOrders() async {
    debugPrint('Manually refreshing orders...');
    _orderService.silentRefresh();
    notifyListeners();
  }
  
  // Perform a silent refresh without showing loading indicators
  Future<void> silentRefresh() async {
    debugPrint('Silently refreshing orders...');
    _orderService.silentRefresh();
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Cancel the auto-refresh timer
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
