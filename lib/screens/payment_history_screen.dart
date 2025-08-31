import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? subscriptionId; // Optional for specific subscription history

  const PaymentHistoryScreen({Key? key, this.subscriptionId}) : super(key: key);

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedFilter = 'all';
  Map<String, dynamic> _historyStats = {};

  @override
  void initState() {
    super.initState();
    _loadHistoryStats();
  }

  Future<void> _loadHistoryStats() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final stats = await firebaseService.getHistoryStats();
    if (mounted) {
      setState(() {
        _historyStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHistoryLimitBanner(),
          _buildFilterSection(),
          Expanded(child: _buildPaymentList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        widget.subscriptionId != null ? 'Payment History' : 'All Payments',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
      ),
    );
  }

  Widget _buildHistoryLimitBanner() {
    if (_historyStats.isEmpty) return SizedBox.shrink();

    final isPremium = _historyStats['isPremium'] ?? false;
    final availableCount = _historyStats['availableHistoryCount'] ?? 0;
    final totalCount = _historyStats['totalHistoryCount'] ?? 0;
    final historyLimit = _historyStats['historyLimit'] ?? '';

    if (totalCount <= availableCount) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
              ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
              : [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.primary : AppColors.secondary).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.star : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                isPremium ? 'Premium History Access' : 'Limited History Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            isPremium 
                ? 'Showing $availableCount of $totalCount total payments ($historyLimit access)'
                : 'Showing $availableCount of $totalCount total payments ($historyLimit limit)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (!isPremium) ...[
            SizedBox(height: 12),
            GestureDetector(
              onTap: _upgradeToPremium,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upgrade, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Upgrade for 2-year history',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Filter:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Payments'),
                  SizedBox(width: 8),
                  _buildFilterChip('overdue_paid', 'Overdue Paid'),
                  SizedBox(width: 8),
                  _buildFilterChip('renewed', 'Regular Renewals'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPaymentList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPaymentHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Loading payment history...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                SizedBox(height: 16),
                Text(
                  'Error loading payment history',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final filteredPayments = _filterPayments(snapshot.data!);
        
        if (filteredPayments.isEmpty) {
          return _buildEmptyFilterState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredPayments.length,
          itemBuilder: (context, index) {
            return _buildPaymentCard(filteredPayments[index]);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getPaymentHistory() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    if (widget.subscriptionId != null) {
      return await firebaseService.getPaymentHistory(widget.subscriptionId!);
    } else {
      return await firebaseService.getAllPaymentHistory();
    }
  }

  List<Map<String, dynamic>> _filterPayments(List<Map<String, dynamic>> payments) {
    if (_selectedFilter == 'all') return payments;
    
    return payments.where((payment) => payment['status'] == _selectedFilter).toList();
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    DateTime paidDate = (payment['paidDate'] as Timestamp).toDate();
    bool isOverdue = payment['status'] == 'overdue_paid';
    String subscriptionName = payment['subscriptionName'] ?? 'Unknown';
    double amount = (payment['amount'] ?? 0.0).toDouble();
    String currency = payment['currency'] ?? 'USD';
    String billingCycle = payment['billingCycle'] ?? 'monthly';
    int daysOverdue = payment['daysOverdue'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? AppColors.error.withOpacity(0.3) : AppColors.divider,
          width: 1,
        ),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isOverdue ? AppColors.error : AppColors.success).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: isOverdue ? AppColors.error : AppColors.success,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscriptionName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      Helpers.formatBillingCycle(billingCycle),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatCurrency(amount, currency: currency),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    Helpers.formatDate(paidDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              
              if (isOverdue && daysOverdue > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Was $daysOverdue days overdue',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
              Icons.history,
              size: 80,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24),
            Text(
              'No Payment History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.subscriptionId != null
                  ? 'This subscription has no payment history yet.'
                  : 'You haven\'t made any payments yet.\nStart by adding subscriptions and marking them as paid.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    String filterText = _selectedFilter == 'overdue_paid' 
        ? 'overdue payments' 
        : 'regular renewals';
        
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No $filterText found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try selecting a different filter option.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _upgradeToPremium() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to Premium'),
        content: Text('Get access to 2 years of payment history and unlimited subscriptions!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium purchase screen
            },
            child: Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
