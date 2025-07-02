import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/payment_method.dart';
import '../../../providers/payment_methods_provider.dart';
import 'checkout_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    // Load payment methods
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodsProvider>().fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsProvider = context.watch<PaymentMethodsProvider>();
    final paymentMethods = paymentMethodsProvider.paymentMethods
        .where((method) => method.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: paymentMethodsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentMethodsProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${paymentMethodsProvider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          paymentMethodsProvider.fetchPaymentMethods();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : paymentMethods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No payment methods available',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: paymentMethods.length,
                            itemBuilder: (ctx, i) {
                              final paymentMethod = paymentMethods[i];
                              return PaymentMethodTile(
                                paymentMethod: paymentMethod,
                                isSelected: _selectedPaymentMethod?.id == paymentMethod.id,
                                onSelect: () {
                                  setState(() {
                                    _selectedPaymentMethod = paymentMethod;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedPaymentMethod != null
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CheckoutScreen(
                                            paymentMethod: _selectedPaymentMethod!,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Proceed to Checkout'),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback onSelect;

  const PaymentMethodTile({
    Key? key,
    required this.paymentMethod,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPaymentIcon(),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (paymentMethod.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          paymentMethod.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onSelect(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentIcon() {
    // Map payment method types to corresponding icons
    // You can extend this based on your payment methods
    if (paymentMethod.name.toLowerCase().contains('card') ||
        paymentMethod.name.toLowerCase().contains('credit')) {
      return Icons.credit_card;
    } else if (paymentMethod.name.toLowerCase().contains('cash')) {
      return Icons.payments;
    } else if (paymentMethod.name.toLowerCase().contains('paypal')) {
      return Icons.paypal;
    } else if (paymentMethod.name.toLowerCase().contains('mobile') ||
        paymentMethod.name.toLowerCase().contains('phone')) {
      return Icons.phone_android;
    }
    return Icons.payment;
  }
}
