import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezones
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;

    // Request permissions
    await requestPermissions();
  }

  static Future<void> _createNotificationChannels() async {
    // Subscription alerts channel
    const AndroidNotificationChannel subscriptionChannel =
        AndroidNotificationChannel(
          'subscription_alerts',
          'Subscription Alerts',
          description: 'Notifications for upcoming subscription renewals',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

    // Spending alerts channel
    const AndroidNotificationChannel spendingChannel =
        AndroidNotificationChannel(
          'spending_alerts',
          'Spending Alerts',
          description: 'Monthly spending summaries and budget alerts',
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: false,
          showBadge: true,
        );

    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (plugin != null) {
      await plugin.createNotificationChannel(subscriptionChannel);
      await plugin.createNotificationChannel(spendingChannel);
    }
  }

  static Future<bool> requestPermissions() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (plugin != null) {
      final granted = await plugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  // Schedule renewal reminder notifications
  static Future<void> scheduleRenewalReminder(
    SubscriptionModel subscription,
  ) async {
    try {
      final renewalDate = subscription.nextBilling;

      // Cancel existing notifications for this subscription
      await cancelSubscriptionNotifications(subscription.id);

      for (int days in subscription.reminderDays) {
        final notificationDate = renewalDate.subtract(Duration(days: days));

        // Only schedule if the notification date is in the future
        if (notificationDate.isAfter(DateTime.now())) {
          final scheduledDate = tz.TZDateTime.from(notificationDate, tz.local);

          await _notifications.zonedSchedule(
            _generateNotificationId(subscription.id, days),
            _getReminderTitle(subscription.name, days),
            _getReminderBody(subscription, renewalDate),
            scheduledDate,
            _getSubscriptionNotificationDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: _createPayload({
              'subscription_id': subscription.id,
              'subscription_name': subscription.name,
              'type': 'renewal_reminder',
              'days_before': days.toString(),
              'amount': subscription.price.toString(),
              'currency': subscription.currency,
            }),
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling renewal reminder: $e');
    }
  }

  // Schedule monthly spending summary
  static Future<void> scheduleMonthlySpendingSummary(
    double monthlyTotal,
    int month,
  ) async {
    try {
      // Schedule for the 1st of each month at 9 AM
      final now = DateTime.now();
      final scheduledDate = tz.TZDateTime(tz.local, now.year, month, 1, 9, 0);

      await _notifications.zonedSchedule(
        month * 1000, // Unique ID for monthly summary
        '📊 Monthly Spending Summary',
        'You spent ${Helpers.formatCurrency(monthlyTotal)} on subscriptions this month',
        scheduledDate,
        _getSpendingNotificationDetails(),
        // ✅ FIXED: Added required androidScheduleMode parameter
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: _createPayload({
          'type': 'monthly_summary',
          'amount': monthlyTotal.toString(),
          'month': month.toString(),
        }),
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling monthly spending summary: $e');
    }
  }

  // Schedule high spending alert (immediate notification)
  static Future<void> scheduleHighSpendingAlert(
    double amount,
    double threshold,
  ) async {
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        '⚠️ High Spending Alert',
        'Your monthly subscriptions (${Helpers.formatCurrency(amount)}) exceed your budget threshold',
        _getSpendingNotificationDetails(isHighPriority: true),
        payload: _createPayload({
          'type': 'high_spending_alert',
          'amount': amount.toString(),
          'threshold': threshold.toString(),
        }),
      );
    } catch (e) {
      debugPrint('Error scheduling high spending alert: $e');
    }
  }

  // Cancel all notifications for a subscription
  static Future<void> cancelSubscriptionNotifications(
    String subscriptionId,
  ) async {
    try {
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();

      for (var notification in pendingNotifications) {
        final payload = _parsePayload(notification.payload ?? '');
        if (payload['subscription_id'] == subscriptionId) {
          await _notifications.cancel(notification.id);
        }
      }
    } catch (e) {
      debugPrint('Error canceling subscription notifications: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  // Get all scheduled notifications
  static Future<List<PendingNotificationRequest>>
  getScheduledNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting scheduled notifications: $e');
      return [];
    }
  }

  // Test notification
  static Future<void> sendTestNotification() async {
    try {
      await _notifications.show(
        999999,
        '🔔 Test Notification',
        'SubVault notifications are working perfectly!',
        _getSubscriptionNotificationDetails(),
        payload: _createPayload({'type': 'test'}),
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  // Get notification details for subscription alerts
  static NotificationDetails _getSubscriptionNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_alerts',
        'Subscription Alerts',
        channelDescription: 'Notifications for upcoming subscription renewals',
        importance: Importance.high,
        priority: Priority.high,
        color: AppColors.primary,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Get notification details for spending alerts
  static NotificationDetails _getSpendingNotificationDetails({
    bool isHighPriority = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'spending_alerts',
        'Spending Alerts',
        channelDescription: 'Monthly spending summaries and budget alerts',
        importance: isHighPriority
            ? Importance.high
            : Importance.defaultImportance,
        priority: isHighPriority ? Priority.high : Priority.defaultPriority,
        color: isHighPriority ? AppColors.error : AppColors.secondary,
        enableVibration: isHighPriority,
        playSound: isHighPriority,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: isHighPriority,
      ),
    );
  }

  static Future<void> showNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'subvault_channel',
            'SubVault Notifications',
            channelDescription: 'General notifications from SubVault',
            importance: Importance.high,
            priority: Priority.high,
            color: AppColors.primary,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Helper methods
  static int _generateNotificationId(String subscriptionId, int daysBeforeId) {
    return ('${subscriptionId.hashCode}$daysBeforeId'.hashCode).abs() %
        2147483647;
  }

  static String _getReminderTitle(String subscriptionName, int days) {
    if (days == 0) {
      return '🚨 $subscriptionName renews today!';
    } else if (days == 1) {
      return '💳 $subscriptionName renews tomorrow';
    } else {
      return '💳 $subscriptionName renews in $days days';
    }
  }

  static String _getReminderBody(
    SubscriptionModel subscription,
    DateTime renewalDate,
  ) {
    String amount = Helpers.formatCurrency(
      subscription.price,
      symbol: subscription.currency == 'USD' ? '\$' : subscription.currency,
    );
    String date = Helpers.formatShortDate(renewalDate);

    return '$amount will be charged on $date';
  }

  // Create payload string from map
  static String _createPayload(Map<String, String> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  // Parse payload string to map
  static Map<String, String> _parsePayload(String payload) {
    if (payload.isEmpty) return {};

    return Map.fromEntries(
      payload.split('&').map((pair) {
        final parts = pair.split('=');
        return MapEntry(parts as String, parts.length > 1 ? parts[9] : '');
      }),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = _parsePayload(response.payload ?? '');
      final type = payload['type'];

      switch (type) {
        case 'renewal_reminder':
          // Navigate to subscription details
          final subscriptionId = payload['subscription_id'];
          if (subscriptionId != null) {
            debugPrint('Navigate to subscription: $subscriptionId');
            // Navigation logic can be added here later
          }
          break;
        case 'monthly_summary':
          // Navigate to analytics page
          debugPrint('Navigate to analytics page');
          // Navigation logic can be added here later
          break;
        case 'high_spending_alert':
          // Navigate to spending breakdown
          debugPrint('Navigate to spending breakdown');
          // Navigation logic can be added here later
          break;
        case 'test':
          debugPrint('Test notification tapped');
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }
}
