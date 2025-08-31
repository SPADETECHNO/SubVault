import 'dart:ui';
import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    final symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'INR': '₹',
      'CAD': 'C\$', 'AUD': 'A\$', 'JPY': '¥',
    };
    final symbol = symbols[currency] ?? currency;
    
    if (currency == 'JPY') {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
static String getSubscriptionStatus(DateTime nextBilling, {DateTime? createdAt}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final billingDate = DateTime(nextBilling.year, nextBilling.month, nextBilling.day);
  
  final daysUntil = billingDate.difference(today).inDays;
  
  // Handle creation date logic if provided
  if (createdAt != null) {
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final daysSinceCreated = today.difference(createdDate).inDays;
    
    // If created today, always show renewal
    if (createdDate.isAtSameMomentAs(today)) {
      if (daysUntil > 0) {
        return 'Renews in $daysUntil day${daysUntil == 1 ? '' : 's'}';
      } else if (daysUntil == 0) {
        return 'Renews today';
      }
    }
    
    // If created yesterday and billing is today/tomorrow, show renewal
    if (daysSinceCreated == 1 && daysUntil >= 0) {
      if (daysUntil == 0) return 'Renews today';
      if (daysUntil == 1) return 'Renews tomorrow';
      return 'Renews in $daysUntil day${daysUntil == 1 ? '' : 's'}';
    }
  }
  
  // Standard logic for all other cases
  if (daysUntil > 1) {
    return 'Renews in $daysUntil days';
  } else if (daysUntil == 1) {
    return 'Renews tomorrow';
  } else if (daysUntil == 0) {
    return 'Renews today';
  } else {
    return 'Overdue by ${daysUntil.abs()} day${daysUntil.abs() == 1 ? '' : 's'}';
  }
}


static DateTime calculateInitialNextBilling(DateTime startDate, String cycle) {
  final normStart = DateTime(startDate.year, startDate.month, startDate.day);
  
  // Calculate what the FIRST billing date should be from start date
  switch (cycle.toLowerCase()) {
    case 'weekly':
      return normStart.add(Duration(days: 7));
    case 'monthly':
      return addMonths(normStart, 1);
    case 'quarterly':
      return addMonths(normStart, 3);
    case 'yearly':
      return addYears(normStart, 1);
    default:
      return addMonths(normStart, 1);
  }
}

static bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

static bool isTomorrow(DateTime date) {
  final tomorrow = DateTime.now().add(Duration(days: 1));
  return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
}

static bool isYesterday(DateTime date) {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
}


  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format short date
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Get days until date - KEEP THIS SIMPLE
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final diff = targetDate.difference(today).inDays;
    
    return diff;
  }

  static String getRenewalStatus(DateTime nextBilling) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billingDate = DateTime(nextBilling.year, nextBilling.month, nextBilling.day);
    
    final diff = billingDate.difference(today).inDays;
    
    if (diff > 0) {
      // Future renewal - include current day
      final days = diff + 1;
      return 'Renewal in $days day${days == 1 ? '' : 's'}';
    } else if (diff == 0) {
      // Due today
      return 'Due today';
    } else {
      // Overdue
      final overdueDays = diff.abs();
      return 'Overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}';
    }
  }

  static String getRenewalUrgency(DateTime nextBilling) {
    final days = daysUntil(nextBilling);
    
    if (days < 0) return 'overdue';
    if (days <= 1) return 'urgent';
    if (days <= 3) return 'warning';
    if (days <= 7) return 'notice';
    return 'normal';
  }


  // Calendar-aware helper functions
  static int daysInMonth(int year, int month) {
    const List<int> monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isLeapYear(year)) {
      return 29;
    }
    return monthLengths[month - 1];
  }

  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static DateTime addMonths(DateTime date, int monthsToAdd) {
    int newYear = date.year + ((date.month + monthsToAdd - 1) ~/ 12);
    int newMonth = ((date.month + monthsToAdd - 1) % 12) + 1;
    int day = date.day;
    
    // Ensure the day exists in the new month
    int maxDayInNewMonth = daysInMonth(newYear, newMonth);
    if (day > maxDayInNewMonth) {
      day = maxDayInNewMonth;
    }
    
    return DateTime(
      newYear, 
      newMonth, 
      day, 
      date.hour, 
      date.minute, 
      date.second, 
      date.millisecond, 
      date.microsecond
    );
  }

  static DateTime addYears(DateTime date, int yearsToAdd) {
    int newYear = date.year + yearsToAdd;
    int month = date.month;
    int day = date.day;
    
    // Handle February 29th in non-leap years
    if (month == 2 && day == 29 && !isLeapYear(newYear)) {
      day = 28;
    }
    
    return DateTime(
      newYear, 
      month, 
      day, 
      date.hour, 
      date.minute, 
      date.second, 
      date.millisecond, 
      date.microsecond
    );
  }

  static DateTime calculateNextBilling(DateTime startDate, String cycle) {
    final now = DateTime.now();
    DateTime nextBilling = startDate;

    while (nextBilling.isBefore(now) || nextBilling.isAtSameMomentAs(now)) {
      switch (cycle.toLowerCase()) {
        case 'monthly':
          nextBilling = addMonths(nextBilling, 1);
          break;
        case 'yearly':
          nextBilling = addYears(nextBilling, 1);
          break;
        case 'weekly':
          nextBilling = nextBilling.add(const Duration(days: 7));
          break;
        case 'quarterly':
          nextBilling = addMonths(nextBilling, 3);
          break;
        default:
          nextBilling = addMonths(nextBilling, 1);
          break;
      }
    }
    return nextBilling;
  }

  static DateTime renewSubscription(DateTime currentNextBilling, String cycle) {
    switch (cycle.toLowerCase()) {
      case 'monthly':
        return addMonths(currentNextBilling, 1);
      case 'yearly':
        return addYears(currentNextBilling, 1);
      case 'weekly':
        return currentNextBilling.add(const Duration(days: 7));
      case 'quarterly':
        return addMonths(currentNextBilling, 3);
      default:
        return addMonths(currentNextBilling, 1);
    }
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
    if (daysLeft < 0) return const Color(0xFFDC2626); // Red for overdue
    if (daysLeft <= 1) return const Color(0xFFDC2626); // Red
    if (daysLeft <= 3) return const Color(0xFFF59E0B); // Yellow
    if (daysLeft <= 7) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF6B7280); // Gray
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
      case 'quarterly':
        return 'Quarterly';
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
      case 'quarterly':
        return price / 3;
      default:
        return price;
    }
  }
}
