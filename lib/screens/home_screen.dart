import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:subvault/screens/analytics_screen.dart';
import 'package:subvault/screens/subscription_detail_screen.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../services/revenue_cat_service.dart';
import '../models/subscription_model.dart';
import '../widgets/subscription_card.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'add_subscription_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPremium = false;
  Map<String, double> _spendingData = {'monthly': 0.0, 'yearly': 0.0};
  List<SubscriptionModel> _upcomingRenewals = [];
  int _activeSubscriptionCount = 0;
  
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {'USD': 1.0};
  bool _isLoadingRates = false;
  
  // Currency options with symbols
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _checkPremiumStatus();
    await _loadExchangeRates();
    await _loadSpendingData();
    await _loadUpcomingRenewals();
    await _loadActiveSubscriptionCount();
  }

  Future<void> _loadActiveSubscriptionCount() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      
      // Get all active subscriptions
      final subscriptions = await firebaseService.getSubscriptions().first;
      final activeCount = subscriptions.where((sub) => sub.isActive).length;
      
      if (mounted) {
        setState(() {
          _activeSubscriptionCount = activeCount;
        });
      }
    } catch (e) {
      print('Error loading active subscription count: $e');
      if (mounted) {
        setState(() {
          _activeSubscriptionCount = 0;
        });
      }
    }
  }

  Future<void> _loadExchangeRates() async {
    setState(() {
      _isLoadingRates = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = <String, double>{};
        
        if (data['rates'] != null) {
          final ratesData = data['rates'] as Map<String, dynamic>;
          for (var entry in ratesData.entries) {
            rates[entry.key] = (entry.value as num).toDouble();
          }
        }
        
        if (mounted) {
          setState(() {
            _exchangeRates = rates.isNotEmpty ? rates : {'USD': 1.0};
            _isLoadingRates = false;
          });
        }
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      print('Error loading exchange rates: $e');
      // Use fallback rates
      if (mounted) {
        setState(() {
          _exchangeRates = {
            'USD': 1.0,
            'EUR': 0.856,
            'GBP': 0.741,
            'INR': 88.1,
            'CAD': 1.37,
            'AUD': 1.53,
            'JPY': 147.04,
          };
          _isLoadingRates = false;
        });
      }
    }
  }

  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final toRate = _exchangeRates[toCurrency] ?? 1.0;
    
    // Convert to USD first, then to target currency
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final isPremium = await RevenueCatService.isPremiumUser();
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
    }
  }

  Future<void> _loadSpendingData() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      
      // Get all active subscriptions
      final subscriptions = await firebaseService.getSubscriptions().first;
      
      double monthlyTotal = 0.0;
      
      // Calculate total spending in selected currency
      for (var subscription in subscriptions) {
        if (subscription.isActive) {
          final convertedAmount = _convertCurrency(
            subscription.monthlyEquivalent,
            subscription.currency,
            _selectedCurrency,
          );
          monthlyTotal += convertedAmount;
        }
      }
      
      if (mounted) {
        setState(() {
          _spendingData = {
            'monthly': monthlyTotal,
            'yearly': monthlyTotal * 12,
          };
        });
      }
    } catch (e) {
      print('Error loading spending data: $e');
    }
  }

  Future<void> _loadUpcomingRenewals() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      final upcomingRenewals = await firebaseService.getUpcomingRenewals(
        days: 7,
      );
      if (mounted) {
        setState(() {
          _upcomingRenewals = upcomingRenewals;
        });
      }
    } catch (e) {
      print('Error loading upcoming renewals: $e');
    }
  }

  Future<void> _markSubscriptionAsPaid(SubscriptionModel subscription) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.markSubscriptionAsPaid(subscription.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subscription.name} marked as paid!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      _loadInitialData(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as paid'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          dropdownColor: AppColors.primary,
          style: TextStyle(color: Colors.white, fontSize: 14),
          icon: _isLoadingRates 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white70),
                  ),
                )
              : Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
          items: _currencies.map((currency) => DropdownMenuItem<String>(
            value: currency['code'],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currency['symbol']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  currency['code']!,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )).toList(),
          onChanged: _isLoadingRates ? null : (String? newValue) {
            if (newValue != null && newValue != _selectedCurrency) {
              setState(() {
                _selectedCurrency = newValue;
              });
              _loadSpendingData();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spending Overview
                  _buildSpendingOverview(),

                  // Quick Actions
                  _buildQuickActions(),

                  // Upcoming Renewals Section
                  if (_upcomingRenewals.isNotEmpty) _buildUpcomingRenewals(),

                  // All Subscriptions Header
                  _buildSectionHeader(
                    'Your Subscriptions',
                    'Manage all your subscriptions',
                  ),
                ],
              ),
            ),

            // Subscriptions List
            _buildSubscriptionsList(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi ${firebaseService.currentUser?.displayName?.split(' ').first ?? 'there'}! 👋',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (!_isPremium)
            Text(
              'Free Plan • ${AppConstants.freeSubscriptionLimit - _activeSubscriptionCount} slots left',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
      actions: [
        // Premium Badge
        if (_isPremium)
          Container(
            margin: EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
          icon: Icon(Icons.settings_outlined),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildSpendingOverview() {
    final currencySymbol = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!;
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Spending',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildCurrencyDropdown(),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$currencySymbol${_spendingData['monthly']!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSpendingStat(
                  'Yearly Total',
                  '$currencySymbol${_spendingData['yearly']!.toStringAsFixed(2)}',
                  Icons.calendar_view_month,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSpendingStat(
                  'Active Subs',
                  '$_activeSubscriptionCount',
                  Icons.subscriptions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingStat(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              'Add Subscription',
              'Track a new service',
              Icons.add_circle_outline,
              AppColors.primary,
              () => _navigateToAddSubscription(),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              'Analytics',
              'View spending insights',
              Icons.analytics_outlined,
              AppColors.secondary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingRenewals() {
    return Column(
      children: [
        _buildSectionHeader(
          'Upcoming Renewals',
          '${_upcomingRenewals.length} renewals in next 7 days',
        ),
        Container(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: _upcomingRenewals.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                child: CompactSubscriptionCard(
                  subscription: _upcomingRenewals[index],
                  onTap: () =>
                      _viewSubscriptionDetails(_upcomingRenewals[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, child) {
        return StreamBuilder<List<SubscriptionModel>>(
          stream: firebaseService.getSubscriptions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error.toString();
              if (error.contains('failed-precondition') &&
                  error.contains('requires an index')) {
                return _buildMessageView(
                  icon: Icons.warning_amber_rounded,
                  title: 'Setting up database...',
                  subtitle: 'This might take a few minutes. Please wait.',
                  iconColor: AppColors.error,
                );
              }

              return _buildMessageView(
                icon: Icons.error_outline,
                title: 'Something went wrong',
                subtitle: 'Unable to load subscriptions',
                iconColor: AppColors.error,
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildMessageView(
                icon: Icons.subscriptions_outlined,
                title: 'No subscriptions yet',
                subtitle: 'Tap the + button to add your first subscription',
                iconColor: AppColors.textSecondary,
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final subscription = snapshot.data![index];
                return SubscriptionCard(
                  key: ValueKey(subscription.id),
                  subscription: subscription,
                  onTap: () => _viewSubscriptionDetails(subscription),
                  onEdit: () => _editSubscription(subscription),
                  onDelete: () => _deleteSubscription(subscription),
                  onToggleStatus: () => _toggleSubscriptionStatus(subscription),
                  onMarkPaid: () => _markSubscriptionAsPaid(subscription),
                );
              }, childCount: snapshot.data!.length),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageView({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: iconColor),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToAddSubscription,
      backgroundColor: AppColors.primary,
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  Future<void> _navigateToAddSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSubscriptionScreen()),
    );

    if (result == true) {
      _loadInitialData();
    }
  }

  void _viewSubscriptionDetails(SubscriptionModel subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionDetailScreen(
          subscription: subscription,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadInitialData();
      }
    });
  }

  void _editSubscription(SubscriptionModel subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubscriptionScreen(
          editingSubscription: subscription,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadInitialData();
      }
    });
  }

  Future<void> _deleteSubscription(SubscriptionModel subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Subscription'),
        content: Text('Are you sure you want to delete ${subscription.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          DangerButton(
            text: 'Delete',
            width: 100,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebaseService = Provider.of<FirebaseService>(
          context,
          listen: false,
        );
        await firebaseService.deleteSubscription(subscription.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${subscription.name} deleted successfully')),
        );
        _loadInitialData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete subscription'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleSubscriptionStatus(SubscriptionModel subscription) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      await firebaseService.toggleSubscriptionStatus(
        subscription.id,
        !subscription.isActive,
      );

      final status = subscription.isActive ? 'paused' : 'resumed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${subscription.name} $status')));

      _loadInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update subscription'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
