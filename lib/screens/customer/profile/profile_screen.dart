import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/customer_auth_service.dart';
import '../../../providers/customer_provider.dart';
import '../home/game_home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final customerProvider = context.read<CustomerProvider>();
    final authService = context.read<CustomerAuthService>();
    
    if (authService.isLoggedIn && authService.user != null) {
      setState(() => _isLoading = true);
      await customerProvider.loadCustomerData(authService.user!.uid);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _signOut() async {
    final authService = context.read<CustomerAuthService>();
    
    setState(() => _isLoading = true);
    await authService.signOut();
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  String getInitial(dynamic customerData, CustomerAuthService authService) {
    // Try to use customer name first
    if (customerData != null && customerData.name != null && customerData.name.toString().isNotEmpty) {
      return customerData.name.toString().substring(0, 1).toUpperCase();
    }
    
    // Fallback to phone number if available
    if (authService.user != null && authService.user!.phoneNumber != null && 
        authService.user!.phoneNumber!.isNotEmpty) {
      return authService.user!.phoneNumber![0];
    }
    
    // Default fallback
    return 'A';
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<CustomerAuthService>();
    final customerProvider = context.watch<CustomerProvider>();
    final customerData = customerProvider.currentCustomer;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akoonkayga'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !authService.isLoggedIn
              ? const Center(
                  child: Text('You need to login first'),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: Colors.blue.shade800,
                        child: Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Text(
                                  getInitial(customerData, authService),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                customerData?.name ?? 'Customer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authService.user?.phoneNumber ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Account Options
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                'My Orders',
                                Icons.receipt_long,
                                () => Navigator.pushNamed(context, '/orders'),
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Edit Profile',
                                Icons.edit,
                                () {},
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Notifications',
                                Icons.notifications,
                                () {},
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Payment Methods',
                                Icons.payment,
                                () {},
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Help & Support',
                                Icons.help,
                                () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // App Info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                'About App',
                                Icons.info,
                                () {},
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Terms & Conditions',
                                Icons.description,
                                () {},
                              ),
                              const Divider(),
                              _buildProfileOption(
                                'Privacy Policy',
                                Icons.privacy_tip,
                                () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Logout Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Dalabyadi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akoonkayga',
          ),
        ],
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameHomeScreen(),
                ),
              );
              break;
            case 1:
              Navigator.pushNamed(context, '/cart');
              break;
            case 2:
              Navigator.pushNamed(context, '/orders');
              break;
            case 3:
              // Already on profile
              break;
          }
        },
      ),
    );
  }
  
  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade800),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
