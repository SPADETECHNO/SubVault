import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);
}

class AppStrings {
  static const String appName = 'SubVault';
  static const String tagline = 'Your Secure Subscription Vault';
  
  // Onboarding
  static const String onboarding1Title = 'Track your\nSubscriptions';
  static const String onboarding1Subtitle = 'Take Charge of your subscription\nnever get unexpected deductions';
  
  static const String onboarding2Title = 'Know before\nit\'s too late';
  static const String onboarding2Subtitle = 'Choose from hundreds of existing\nservices or make one of your own';
  
  static const String onboarding3Title = 'Everything\nyou need';
  static const String onboarding3Subtitle = 'Get notifications before you pay for\nyour next subscription';
  
  // Auth
  static const String welcomeBack = 'Welcome back!';
  static const String loginSubtitle = 'Use your credentials below and login\nto your account';
  static const String createAccount = 'Create Account';
  static const String signupSubtitle = 'Create a new account to get started\nwith SubVault';
  
  // Premium
  static const String premiumTitle = 'Upgrade to Premium';
  static const String freeLimit = 'Free users can add up to 6 subscriptions';
  static const String premiumUnlimited = 'Premium: Unlimited subscriptions';
}

class AppConstants {
  static const int freeSubscriptionLimit = 6;
  static const int freeHistoryMonths = 2;
  static const int premiumHistoryMonths = 24;
  static const String revenueCatApiKey = 'goog_IodUJbsCnigMEgrRfurBPYRLBbk';
  
  // Popular services
  static const List<Map<String, String>> popularServices = [
    {'name': 'Netflix', 'icon': 'netflix.png', 'category': 'Entertainment'},
    {'name': 'Spotify', 'icon': 'spotify.png', 'category': 'Music'},
    {'name': 'Disney+', 'icon': 'disney.png', 'category': 'Entertainment'},
    {'name': 'YouTube Premium', 'icon': 'youtube.png', 'category': 'Entertainment'},
    {'name': 'Amazon Prime', 'icon': 'amazon.png', 'category': 'Shopping'},
    {'name': 'Adobe Creative', 'icon': 'adobe.png', 'category': 'Productivity'},
  ];
  
  static const List<String> categories = [
    'Entertainment',
    'Music',
    'Productivity',
    'Shopping',
    'Health & Fitness',
    'News',
    'Education',
    'Gaming',
    'Finance',
    'Other',
  ];
}
