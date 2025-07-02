import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../models/payment_method.dart';
import '../../../providers/payment_methods_provider.dart';
import '../../../services/customer_auth_service.dart';
import '../../../services/order_service.dart';
import 'payment_success_screen.dart';
import '../../../utils/firebase_image_helper.dart';

class GameCheckoutScreen extends StatefulWidget {
  final Product product;

  const GameCheckoutScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<GameCheckoutScreen> createState() => _GameCheckoutScreenState();
}

class _GameCheckoutScreenState extends State<GameCheckoutScreen> {
  final TextEditingController _gameIdController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _initPhoneNumber();
  }

  void _initPhoneNumber() {
    final authService = context.read<CustomerAuthService>();
    if (authService.isLoggedIn && authService.user != null) {
      _phoneController.text = authService.user!.phoneNumber ?? '';
    }
  }

  void _loadPaymentMethods() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodsProvider>().fetchPaymentMethods();
    });
  }

  void _submitOrder() async {
    if (_gameIdController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your game ID';
      });
      return;
    }

    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }
    
    // Check if phone number is provided
    if (_phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }
    
    // Get auth service
    final authService = context.read<CustomerAuthService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // We already have authService from above
      final orderService = context.read<OrderService>();
      
      // Create game-specific order details
      final orderDetails = {
        'gameId': _gameIdController.text,
        'playerName': _playerNameController.text,
        'productId': widget.product.id,
        'productName': widget.product.name,
        'price': widget.product.price,
        'paymentMethodId': _selectedPaymentMethod!.id,
        'paymentMethodName': _selectedPaymentMethod!.name,
      };

      // Determine customer ID - use authenticated user ID if available, otherwise use phone number
      String customerId;
      if (authService.isLoggedIn && authService.user != null) {
        customerId = authService.user!.uid;
      } else {
        // For guest users, use phone number as identifier with a prefix
        customerId = 'guest_${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';
      }

      final orderId = await orderService.createCustomerOrder(
        customerId: customerId,
        phoneNumber: _phoneController.text,
        amount: widget.product.price,
        paymentMethodId: _selectedPaymentMethod!.id,
        status: 'pending',
        items: [
          {
            'productId': widget.product.id,
            'name': widget.product.name,
            'price': widget.product.price,
            'quantity': 1,
          }
        ],
        orderDetails: orderDetails,
      );

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            orderId: orderId,
            amount: widget.product.price,
            paymentMethod: _selectedPaymentMethod!,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create order: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsProvider = context.watch<PaymentMethodsProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name.toUpperCase()),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone number section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          _phoneController.text.isNotEmpty 
                              ? _phoneController.text 
                              : 'Add Phone Number',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Game info form
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buuxi Macluumaadkan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'FadLAN ka buuxi macluumaadka hoose 00 dhameystiran',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Game ID Field
                        TextField(
                          controller: _gameIdController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.tag),
                            prefixText: '# ',
                            hintText: 'ID Pubg kaga',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Player Name Field
                        TextField(
                          controller: _playerNameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            hintText: 'Magaca Game kugu qoran',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Phone Number Field
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone),
                            hintText: 'Number lacagta kasoo dirtay',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Payment Methods Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dooro habka aad lacagta ku bixineysid',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Found ${paymentMethodsProvider.paymentMethods.length} payment methods',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Payment Methods Grid
                        paymentMethodsProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : paymentMethodsProvider.error != null
                                ? Center(
                                    child: Text('Error: ${paymentMethodsProvider.error}'),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: paymentMethodsProvider.paymentMethods.length,
                                    itemBuilder: (context, index) {
                                      final paymentMethod = paymentMethodsProvider.paymentMethods[index];
                                      final isSelected = _selectedPaymentMethod?.id == paymentMethod.id;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedPaymentMethod = paymentMethod;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (paymentMethod.imageUrl != null && paymentMethod.imageUrl!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: FirebaseImageWidget(
                                                    imageUrl: paymentMethod.imageUrl,
                                                    width: 60,
                                                    height: 40,
                                                    fit: BoxFit.contain,
                                                    borderRadius: BorderRadius.circular(4),
                                                    placeholder: SizedBox(
                                                      height: 40,
                                                      width: 60,
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.blue.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget: Icon(
                                                      paymentMethod.icon ?? Icons.payment, 
                                                      size: 40, 
                                                      color: paymentMethod.color ?? Colors.blue.shade800,
                                                    ),
                                                  ),
                                                )
                                              else
                                                Icon(
                                                  paymentMethod.icon ?? Icons.payment, 
                                                  size: 40, 
                                                  color: paymentMethod.color ?? Colors.blue.shade800,
                                                ),
                                              const SizedBox(height: 4),
                                              Text(
                                                paymentMethod.name,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                  
                  // Payment Instructions
                  if (_selectedPaymentMethod != null)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              const Text(
                                'Payment Instructions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'FG Markaad Lacagta Bixiso Riix Halka Hoose Ee Ku Qoran Tahay Waan Bixiyey Lacagta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Magaca kuusoo baaxaya: AXMED Muxudiin CALI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // Pay Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle),
                          const SizedBox(width: 8),
                          Text(
                            'BIXI \$${widget.product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _gameIdController.dispose();
    _playerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
