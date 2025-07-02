import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/store_order.dart';

class OrderService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');
  
  List<StoreOrder> _orders = [];
  List<StoreOrder> _pendingOrders = [];
  List<StoreOrder> _completedOrders = [];
  List<StoreOrder> _canceledOrders = [];
  bool _isLoading = false;
  String? _error;
  int _newOrdersCount = 0;
  
  // Store the last known order count to detect changes
  int _lastPendingOrderCount = 0;
  int _lastCompletedOrderCount = 0;
  int _lastCanceledOrderCount = 0;
  
  // Getters
  List<StoreOrder> get orders => _orders;
  List<StoreOrder> get pendingOrders => _pendingOrders;
  List<StoreOrder> get completedOrders => _completedOrders;
  List<StoreOrder> get canceledOrders => _canceledOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get newOrdersCount => _newOrdersCount;
  
  // Initialize and listen for orders
  void init() {
    debugPrint('🔍 INITIALIZING ORDER SERVICE');
    debugPrint('🔍 Firestore instance: ${_firestore.app.name}');
    debugPrint('🔍 Orders collection path: ${_ordersCollection.path}');
    
    // First try a direct fetch to see if we can access the data
    fetchOrdersOnce();
    
    // Then set up the listeners
    _listenForOrders();
    _listenForNewOrders();
  }
  
  // Debug method to fetch orders once and log them
  Future<void> fetchOrdersOnce() async {
    try {
      debugPrint('🔍 Fetching orders from Firestore...');
      
      // First check if we can access Firestore at all
      try {
        final collections = await _firestore.collection('orders').get();
        debugPrint('🔍 Successfully connected to Firestore');
        debugPrint('🔍 Orders collection has ${collections.docs.length} documents');
      } catch (e) {
        debugPrint('❌ Error accessing Firestore: $e');
      }
      
      // Now try to get the orders
      final snapshot = await _ordersCollection.get();
      debugPrint('🔍 Firestore returned ${snapshot.docs.length} orders');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No orders found in Firestore. Collection may be empty or path may be incorrect.');
        
        // Check if we're using the correct collection path
        debugPrint('🔍 Using collection path: ${_ordersCollection.path}');
        
        // Try to list other collections (commented out due to API limitations)
        debugPrint('🔍 Unable to list root collections due to API limitations');
      } else {
        for (var doc in snapshot.docs) {
          debugPrint('🔍 Order found: ${doc.id}');
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('🔍 Order data: ${data.keys.join(", ")}');
          debugPrint('🔍 Order status: ${data['status']}');
          debugPrint('🔍 Order customer: ${data['customerName']}');
          
          try {
            final order = StoreOrder.fromFirestore(doc);
            debugPrint('✅ Successfully parsed order: ${order.id}');
          } catch (e) {
            debugPrint('❌ Error parsing order ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
    }
  }
  
  // Listen for all orders
  void _listenForOrders() {
    _isLoading = true;
    notifyListeners();
    
    debugPrint('🔍 Setting up order listener on collection: orders');
    
    // Use createdAt for ordering, with fallback to date field
    _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔍 Order snapshot received with ${snapshot.docs.length} documents');
      
      _orders = snapshot.docs.map((doc) {
        try {
          return StoreOrder.fromFirestore(doc);
        } catch (e) {
          debugPrint('❌ Error parsing order ${doc.id}: $e');
          debugPrint('❌ Document data: ${doc.data()}');
          return null;
        }
      }).whereType<StoreOrder>().toList();
      
      debugPrint('🔍 Parsed ${_orders.length} valid orders');
      
      // Filter orders by status
      _pendingOrders = _orders.where((order) => order.status == 'pending').toList();
      _completedOrders = _orders.where((order) => order.status == 'completed').toList();
      _canceledOrders = _orders.where((order) => order.status == 'canceled').toList();
      
      debugPrint('🔍 Orders by status: Pending: ${_pendingOrders.length}, Completed: ${_completedOrders.length}, Canceled: ${_canceledOrders.length}');
      
      // Check for new orders since last update
      _checkForNewOrders();
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      _error = 'Error loading orders: $e';
      debugPrint('❌ Error in order listener: $e');
      notifyListeners();
    });
  }
  
  // Check for changes in order counts
  void _checkForNewOrders() {
    if (_pendingOrders.length != _lastPendingOrderCount) {
      debugPrint('🔔 Pending orders count changed: ${_lastPendingOrderCount} -> ${_pendingOrders.length}');
      _lastPendingOrderCount = _pendingOrders.length;
    }
    
    if (_completedOrders.length != _lastCompletedOrderCount) {
      debugPrint('🔔 Completed orders count changed: ${_lastCompletedOrderCount} -> ${_completedOrders.length}');
      _lastCompletedOrderCount = _completedOrders.length;
    }
    
    if (_canceledOrders.length != _lastCanceledOrderCount) {
      debugPrint('🔔 Canceled orders count changed: ${_lastCanceledOrderCount} -> ${_canceledOrders.length}');
      _lastCanceledOrderCount = _canceledOrders.length;
    }
  }
  
  // Listen for new orders (orders with payment completed but still pending admin approval)
  void _listenForNewOrders() {
    _ordersCollection
        .where('status', isEqualTo: 'pending')
        .where('paymentStatus', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      _newOrdersCount = snapshot.docs.length;
      debugPrint('🔍 New orders count: $_newOrdersCount');
      notifyListeners();
    }, onError: (e) {
      debugPrint('❌ Error in new orders listener: $e');
    });
  }
  
  // Reset new orders count
  void resetNewOrdersCount() {
    _newOrdersCount = 0;
    notifyListeners();
  }
  
  // Update order status to any status (pending, completed, canceled)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (!['pending', 'completed', 'canceled'].contains(newStatus)) {
        debugPrint('❌ Invalid status: $newStatus. Must be pending, completed, or canceled.');
        return false;
      }

      // Update order status
      await _ordersCollection.doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Order $orderId status updated to: $newStatus');
      await silentRefresh();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      return false;
    }
  }

  // Create a new customer order
  Future<String> createCustomerOrder({
    required String customerId,
    required String phoneNumber,
    required double amount,
    required String paymentMethodId,
    required String status,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? orderDetails,
  }) async {
    try {
      // Create a new order document
      final newOrderRef = _ordersCollection.doc();
      
      final now = Timestamp.now();
      final orderData = {
        'customerId': customerId,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'paymentMethodId': paymentMethodId,
        'items': items,
        'status': status,
        'paymentStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      };
      
      // Add order details if provided
      if (orderDetails != null) {
        orderData['details'] = orderDetails;
      }
      
      await newOrderRef.set(orderData);
      
      debugPrint('✅ New customer order created with ID: ${newOrderRef.id}');
      return newOrderRef.id;
    } catch (e) {
      debugPrint('❌ Error creating customer order: $e');
      throw e;
    }
  }
  
  // Fetch orders for a specific customer
  Future<List<StoreOrder>> fetchCustomerOrders(String customerId) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('userPhoneNumber', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final orders = querySnapshot.docs.map((doc) {
        return StoreOrder.fromFirestore(doc);
      }).toList();
      
      debugPrint('✅ Fetched ${orders.length} orders for customer $customerId');
      return orders;
    } catch (e) {
      debugPrint('❌ Error fetching customer orders: $e');
      return []; // Return empty list instead of throwing
    }
  }
  
  // Complete an order
  Future<bool> completeOrder(String orderId) async {
    return updateOrderStatus(orderId, 'completed');
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, 'canceled');
  }

  // Reset to pending
  Future<bool> setPendingOrder(String orderId) async {
    return updateOrderStatus(orderId, 'pending');
  }
  
  // Get orders by date range
  List<StoreOrder> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders.where((StoreOrder order) {
      return order.createdAt.isAfter(startDate) && 
             order.createdAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  // Get orders by payment method
  List<StoreOrder> getOrdersByPaymentMethod(String paymentMethod) {
    return _orders.where((StoreOrder order) => 
      order.paymentMethod.toLowerCase() == paymentMethod.toLowerCase()
    ).toList();
  }
  
  // Search orders by customer name, payment number, or game ID
  List<StoreOrder> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    
    final lowercaseQuery = query.toLowerCase();
    return _orders.where((StoreOrder order) {
      return order.customerName.toLowerCase().contains(lowercaseQuery) ||
             order.paymentNumber.toLowerCase().contains(lowercaseQuery) ||
             order.gameId.toLowerCase().contains(lowercaseQuery) ||
             order.id.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  // Get total sales amount
  double getTotalSales() {
    // Only include completed orders in revenue calculations
    final total = _completedOrders.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    
    // Debug logs
    debugPrint('💰 Total sales calculation:');
    debugPrint('💰 Completed orders count: ${_completedOrders.length}');
    debugPrint('💰 Total sales amount: \$${total.toStringAsFixed(2)}');
    
    // Verify we're not including other orders
    final pendingTotal = _pendingOrders.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    final canceledTotal = _canceledOrders.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    debugPrint('💰 Pending orders total (NOT included): \$${pendingTotal.toStringAsFixed(2)}');
    debugPrint('💰 Canceled orders total (NOT included): \$${canceledTotal.toStringAsFixed(2)}');
    
    return total;
  }
  
  // Get total sales for a specific date range
  double getTotalSalesForDateRange(DateTime startDate, DateTime endDate) {
    // Filter orders by date range first
    final ordersInRange = getOrdersByDateRange(startDate, endDate);
    
    // Filter for completed orders only
    final completedOrdersInRange = ordersInRange.where((StoreOrder order) => order.status == 'completed').toList();
    
    // Calculate total
    final total = completedOrdersInRange.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    
    // Debug logs
    debugPrint('💰 Date range sales calculation:');
    debugPrint('💰 Date range: ${startDate.toString()} to ${endDate.toString()}');
    debugPrint('💰 All orders in range: ${ordersInRange.length}');
    debugPrint('💰 Completed orders in range: ${completedOrdersInRange.length}');
    debugPrint('💰 Total sales in range: \$${total.toStringAsFixed(2)}');
    
    // Verify we're not including other orders
    final pendingInRange = ordersInRange.where((order) => order.status == 'pending').toList();
    final canceledInRange = ordersInRange.where((order) => order.status == 'canceled').toList();
    final pendingTotal = pendingInRange.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    final canceledTotal = canceledInRange.fold(0.0, (double sum, StoreOrder order) => sum + order.price);
    debugPrint('💰 Pending orders in range (NOT included): ${pendingInRange.length} orders, \$${pendingTotal.toStringAsFixed(2)}');
    debugPrint('💰 Canceled orders in range (NOT included): ${canceledInRange.length} orders, \$${canceledTotal.toStringAsFixed(2)}');
    
    return total;
  }
  
  // Try a direct query to create a test order (for debugging only)
  Future<void> createTestOrder() async {
    try {
      debugPrint('🔍 Attempting to create a test order...');
      
      // Current timestamp
      final now = DateTime.now();
      
      // Create a test order
      final testOrder = {
        'gameType': 'Test Game',
        'gameTitle': 'Test Title',
        'creditAmount': '100',
        'price': 10.0,
        'gameId': 'test123',
        'customerName': 'Test Customer',
        'paymentNumber': '1234567890',
        'paymentMethod': 'Test Payment',
        'status': 'pending',
        'paymentStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      };
      
      // Save to Firestore
      final docRef = await _ordersCollection.add(testOrder);
      debugPrint('✅ Test order created with ID: ${docRef.id}');
      
    } catch (e) {
      debugPrint('❌ Error creating test order: $e');
    }
  }
  
  // Fetch orders without showing loading indicators
  Future<void> silentRefresh() async {
    try {
      debugPrint('🔍 Silently refreshing orders from Firestore...');
      
      // Fetch orders without setting loading state
      final snapshot = await _ordersCollection.orderBy('createdAt', descending: true).get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No orders found in Firestore during silent refresh.');
        return;
      }
      
      // Process orders without showing loading indicators
      _orders = snapshot.docs.map((doc) {
        try {
          return StoreOrder.fromFirestore(doc);
        } catch (e) {
          debugPrint('❌ Error parsing order ${doc.id}: $e');
          return null;
        }
      }).whereType<StoreOrder>().toList();
      
      // Update filtered lists
      _pendingOrders = _orders.where((order) => order.status == 'pending').toList();
      _completedOrders = _orders.where((order) => order.status == 'completed').toList();
      _canceledOrders = _orders.where((order) => order.status == 'canceled').toList();
      
      // Check for changes in order counts
      _checkForNewOrders();
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error during silent refresh: $e');
    }
  }
  
  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}
