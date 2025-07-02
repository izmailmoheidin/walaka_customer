import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/customer_auth_service.dart';
import '../../providers/customer_provider.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({Key? key}) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  void _loadCustomerData() {
    final authService = context.read<CustomerAuthService>();
    final customerProvider = context.read<CustomerProvider>();
    
    if (authService.isLoggedIn && authService.user != null) {
      customerProvider.loadCustomerData(authService.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<CustomerAuthService>();
    final customerProvider = context.watch<CustomerProvider>();
    final customer = customerProvider.currentCustomer;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authService.user?.phoneNumber ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
