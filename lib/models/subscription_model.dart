import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

enum BillingCycle { monthly, yearly, weekly }

class SubscriptionModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime nextBilling;
  final DateTime startDate;
  final String iconUrl;
  final bool isActive;
  final String? description;
  final String? website;
  final List<int> reminderDays;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.price,
    this.currency = 'USD',
    required this.billingCycle,
    required this.nextBilling,
    required this.startDate,
    required this.iconUrl,
    this.isActive = true,
    this.description,
    this.website,
    this.reminderDays = const [7, 3, 1],
    required this.createdAt,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == data['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      nextBilling: (data['nextBilling'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      iconUrl: data['iconUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      description: data['description'],
      website: data['website'],
      reminderDays: List<int>.from(data['reminderDays'] ?? [7, 3, 1]),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle.name,
      'nextBilling': Timestamp.fromDate(nextBilling),
      'startDate': Timestamp.fromDate(startDate),
      'iconUrl': iconUrl,
      'isActive': isActive,
      'description': description,
      'website': website,
      'reminderDays': reminderDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.now(),
    };
  }

  // Calculate monthly equivalent for analytics
  double get monthlyEquivalent {
    return Helpers.getMonthlyEquivalent(price, billingCycle.name);
  }

  // Get days until next billing
  int get daysUntilBilling {
    return Helpers.daysUntil(nextBilling);
  }

  // Check if renewal is urgent (within 3 days)
  bool get isRenewalUrgent {
    return daysUntilBilling <= 3;
  }

  // Get formatted billing cycle
  String get formattedBillingCycle {
    return Helpers.formatBillingCycle(billingCycle.name);
  }

  // Get formatted price with currency
  String get formattedPrice {
    return Helpers.formatCurrency(price, symbol: currency == 'USD' ? '\$' : currency);
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? nextBilling,
    DateTime? startDate,
    String? iconUrl,
    bool? isActive,
    String? description,
    String? website,
    List<int>? reminderDays,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBilling: nextBilling ?? this.nextBilling,
      startDate: startDate ?? this.startDate,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      website: website ?? this.website,
      reminderDays: reminderDays ?? this.reminderDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
