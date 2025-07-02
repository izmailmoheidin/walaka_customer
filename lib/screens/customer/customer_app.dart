import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/customer_theme.dart';
import '../../services/customer_auth_service.dart';
import '../../providers/customer_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/payment_methods_provider.dart';
import '../../services/order_service.dart';
import 'auth/phone_login_screen.dart';
import 'auth/auth_wrapper.dart';
import 'home/game_home_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class CustomerApp extends StatelessWidget {
  const CustomerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerAuthService()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodsProvider()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Walalka Store',
        theme: CustomerTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const CustomerAuthWrapper(),
          '/home': (context) => const GameHomeScreen(),
          '/login': (context) => const PhoneLoginScreen(),
          '/cart': (context) => const CartScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
