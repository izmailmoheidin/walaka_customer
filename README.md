# Walalka Customer App

Customer-facing application for the Walalka e-commerce platform. This project provides the shopping experience for customers, including browsing products, adding items to cart, and completing purchases.

## Project Structure

```
lib/
├── constants/            # App-wide constants and configurations
├── models/               # Data models for Firebase objects
├── providers/            # State management providers
├── screens/
│   ├── customer/
│       ├── auth/         # Authentication screens
│       ├── cart/         # Shopping cart
│       ├── home/         # Home screen and navigation
│       ├── orders/       # Order history and tracking
│       ├── payment/      # Payment methods and checkout
│       ├── products/     # Product browsing and details
│       ├── profile/      # User profile management
├── services/             # Firebase and other API services
├── theme/                # Theme configuration
├── utils/                # Utility functions and helper classes
└── main.dart             # Application entry point
```

## Features

- Customer authentication via phone number
- Product browsing by category
- Product details and media display
- Shopping cart functionality
- Checkout and payment processing
- Order history and status tracking
- User profile management
- Firebase integration for backend services

## Setup Instructions

1. Ensure Flutter is installed (2.5.0 or later)
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` for development

## Firebase Configuration

This application uses Firebase for authentication, database, and storage. The Firebase project is already configured in the main.dart file.

## Deployment

### Web
To build for web:

```
flutter build web --release --web-renderer html
```

### Mobile
To build for Android:

```
flutter build apk --release
```

For iOS:

```
flutter build ios --release
```
#   w a l a k a _ c u s t o m e r  
 