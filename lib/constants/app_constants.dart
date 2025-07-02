class AppConstants {
  // App
  static const String appName = 'Walalka Store Admin';

  // Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';

  // Storage
  static const String productImagesPath = 'products';
  static const String categoryImagesPath = 'categories';
  static const String userImagesPath = 'users';

  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String productsRoute = '/products';
  static const String ordersRoute = '/orders';
  static const String usersRoute = '/users';
  static const String settingsRoute = '/settings';

  // Error Messages
  static const String defaultError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Invalid email or password.';
  static const String permissionError = 'You do not have permission to perform this action.';
}
