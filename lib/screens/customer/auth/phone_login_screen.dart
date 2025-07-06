import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/customer_auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../constants/app_constants.dart';
import '../../customer/home/game_home_screen.dart';
import 'package:flutter/foundation.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Accept any phone number format for easier testing
    return null;
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = context.read<CustomerAuthService>();
      String phoneNumber = _phoneController.text.trim();
      
      // Ensure the phone number has the correct format
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }
      
      // Call the direct login method that skips OTP verification
      final success = await authService.directLoginWithPhone(phoneNumber);
      
      // No need to navigate - auth_wrapper will handle redirection if login is successful
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<CustomerAuthService>();
    final isLoading = authService.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Login', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
        leading: Navigator.canPop(context) ? BackButton(color: Colors.blue.shade800) : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black.withBlue(30),
                ],
              )
            : AppTheme.backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: AppTheme.logoDecoration,
                            child: Center(
                              child: Image.asset(
                                'assets/images/new_logo.png',
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (context, _, __) => Icon(
                                  Icons.storefront,
                                  size: 60,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // App Name
                        Text(
                          'Walalka Store',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Shop anytime, anywhere',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Login instruction
                        Text(
                          'Enter your phone number to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Phone number input field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: AppTheme.inputDecoration(
                            'Phone Number',
                            hint: 'Enter your phone number',
                            prefixIcon: const Icon(Icons.phone),
                          ).copyWith(prefixText: '+252 '),
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 24),
                        
                        // Error message
                        if (authService.error != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              authService.error!,
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (authService.error != null) const SizedBox(height: 16),
                        
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authService.isLoading ? null : _login,
                            style: AppTheme.primaryButtonStyle,
                            child: authService.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Development mode notice
                        if (kDebugMode)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              'Development Mode - Login without OTP',
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (kDebugMode) const SizedBox(height: 8),
                        
                        // Help text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Having trouble logging in?',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Add help functionality if needed
                              },
                              child: Text('Get Help', 
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
