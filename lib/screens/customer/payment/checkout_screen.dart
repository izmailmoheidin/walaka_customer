import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/payment_method.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../services/customer_auth_service.dart';
import 'payment_success_screen.dart';
import '../../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  final PaymentMethod paymentMethod;

  const CheckoutScreen({
    Key? key,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadCustomerData() {
    final authService = context.read<CustomerAuthService>();
    final customerProvider = context.read<CustomerProvider>();
    
    if (authService.isLoggedIn && authService.user != null) {
      customerProvider.loadCustomerData(authService.user!.uid).then((_) {
        final customer = customerProvider.currentCustomer;
        if (customer != null) {
          _nameController.text = customer.name ?? '';
          _emailController.text = customer.email ?? '';
          _addressController.text = customer.address ?? '';
        }
      });
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<CustomerAuthService>();
      final cartProvider = context.read<CartProvider>();
      final customerProvider = context.read<CustomerProvider>();
      
      // Prepare order data
      final userId = authService.user?.uid;
      final customerName = _nameController.text.trim();
      final customerEmail = _emailController.text.trim();
      final deliveryAddress = _addressController.text.trim();
      final cartItems = cartProvider.items.values.toList();
      final totalAmount = cartProvider.totalAmount;

      // Save customer info if logged in
      if (userId != null) {
        await customerProvider.updateProfile(
          userId: userId,
          name: customerName,
          email: customerEmail,
          address: deliveryAddress,
        );
      }

      // Create order using OrderService
      final orderId = await OrderService().createCustomerOrder(
        customerId: userId ?? '',
        phoneNumber: customerEmail, // Using email as phone for compatibility
        amount: totalAmount,
        paymentMethodId: widget.paymentMethod.id,
        status: 'pending',
        items: cartItems.map((item) => {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
        }).toList(),
        orderDetails: {
          'customerName': customerName,
          'deliveryAddress': deliveryAddress,
          'email': customerEmail,
        },
      );

      // Clear the cart
      cartProvider.clear();

      // Navigate to success screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: orderId,
              amount: totalAmount,
              paymentMethod: widget.paymentMethod,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information Section
                      Text(
                        'Customer Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Enter your delivery address',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter delivery address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Order Summary Section
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...cartProvider.items.values.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item.product.name),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Payment Method Section
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.payment),
                          title: Text(widget.paymentMethod.name),
                          subtitle: widget.paymentMethod.description != null
                              ? Text(widget.paymentMethod.description!)
                              : null,
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Change'),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Complete Order Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _processPayment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Complete Order',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
