import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _checkPremiumStatus();
    await _loadSpendingData();
    await _loadUpcomingRenewals();
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
      final spendingData = await firebaseService.getSpendingAnalytics();
      if (mounted) {
        setState(() {
          _spendingData = spendingData;
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
              'Free Plan • ${AppConstants.freeSubscriptionLimit - (_upcomingRenewals.length)} slots left',
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

        // Settings Button
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
          Text(
            'Monthly Spending',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            Helpers.formatCurrency(_spendingData['monthly'] ?? 0.0),
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
                  Helpers.formatCurrency(_spendingData['yearly'] ?? 0.0),
                  Icons.calendar_view_month,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSpendingStat(
                  'Active Subs',
                  '${_upcomingRenewals.length}',
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
                // TODO: Navigate to analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Analytics coming soon!')),
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
                  subscription: subscription,
                  onTap: () => _viewSubscriptionDetails(subscription),
                  onEdit: () => _editSubscription(subscription),
                  onDelete: () => _deleteSubscription(subscription),
                  onToggleStatus: () => _toggleSubscriptionStatus(subscription),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              'No Subscriptions Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your subscriptions to take control of your spending',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            SizedBox(height: 32),
            PrimaryButton(
              text: 'Add Your First Subscription',
              onPressed: _navigateToAddSubscription,
              icon: Icons.add,
              width: 250,
            ),
          ],
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
    // TODO: Navigate to subscription details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscription details coming soon!')),
    );
  }

  void _editSubscription(SubscriptionModel subscription) {
    // TODO: Navigate to edit subscription
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit subscription coming soon!')));
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
            width: 80,
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
