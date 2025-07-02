import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/customer/customer_app.dart';
import 'theme/customer_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with specific options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDUf1eQrAvFEE1QGKdptZYUUjtUeR4gGCE',
      appId: '1:1098551538170:android:6420ec9f022b733a7cb443',
      messagingSenderId: '1098551538170',
      projectId: 'walalka-store-a06ef',
      storageBucket: 'walalka-store-a06ef.firebasestorage.app',
    ),
  );
  
  // Configure Firebase Auth to not depend on Google Play Services
  FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  
  // Enable Firestore logging for debugging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Run the customer app
  runApp(const CustomerApp());
}
