import 'dart:ui';
import 'package:intl/intl.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    final symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'INR': '₹',
      'CAD': 'C\$', 'AUD': 'A\$', 'JPY': '¥',
    };
    
    final symbol = symbols[currency] ?? currency;
    
    // Format based on currency (JPY has no decimals, etc.)
    if (currency == 'JPY') {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  // Format short date
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Get days until date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
  
  // Calculate next billing date
  static DateTime calculateNextBilling(DateTime startDate, String cycle) {
    final now = DateTime.now();
    DateTime nextBilling = startDate;
    
    while (nextBilling.isBefore(now) || nextBilling.isAtSameMomentAs(now)) {
      switch (cycle.toLowerCase()) {
        case 'monthly':
          nextBilling = DateTime(nextBilling.year, nextBilling.month + 1, nextBilling.day);
          break;
        case 'yearly':
          nextBilling = DateTime(nextBilling.year + 1, nextBilling.month, nextBilling.day);
          break;
        case 'weekly':
          nextBilling = nextBilling.add(Duration(days: 7));
          break;
        default:
          nextBilling = DateTime(nextBilling.year, nextBilling.month + 1, nextBilling.day);
      }
    }
    
    return nextBilling;
  }
  
  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Get renewal urgency color
  static Color getRenewalUrgencyColor(int daysLeft) {
    if (daysLeft <= 1) return Color(0xFFDC2626); // Red
    if (daysLeft <= 3) return Color(0xFFF59E0B); // Yellow
    if (daysLeft <= 7) return Color(0xFF3B82F6); // Blue
    return Color(0xFF6B7280); // Gray
  }
  
  // Format billing cycle
  static String formatBillingCycle(String cycle) {
    switch (cycle.toLowerCase()) {
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'weekly':
        return 'Weekly';
      default:
        return 'Monthly';
    }
  }
  
  // Calculate monthly equivalent
  static double getMonthlyEquivalent(double price, String cycle) {
    switch (cycle.toLowerCase()) {
      case 'monthly':
        return price;
      case 'yearly':
        return price / 12;
      case 'weekly':
        return price * 4.33; // Average weeks per month
      default:
        return price;
    }
  }
}
