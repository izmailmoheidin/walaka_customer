import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/customer_auth_service.dart';
import '../../../providers/customer_provider.dart';
import '../home/game_home_screen.dart';
import 'phone_login_screen.dart';

class CustomerAuthWrapper extends StatelessWidget {
  final bool redirectToLogin;

  const CustomerAuthWrapper({
    Key? key,
    this.redirectToLogin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<CustomerAuthService>();
    
    // If user is not logged in and we want to redirect, show login screen
    if (!authService.isLoggedIn && redirectToLogin) {
      return const PhoneLoginScreen();
    }
    
    // If user is logged in, load their profile data
    if (authService.isLoggedIn && authService.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CustomerProvider>().loadCustomerData(authService.user!.uid);
      });
    }
    
    // Always return the game home screen - individual screens will handle auth state as needed
    return const GameHomeScreen();
  }
}
