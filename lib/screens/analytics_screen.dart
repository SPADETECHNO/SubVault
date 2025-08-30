import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firebase_service.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _spendingData = {};
  Map<String, double> _categoryData = {};
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = true;
  String _selectedCurrency = 'USD';
  Map<String, double> _exchangeRates = {'USD': 1.0};

  // Time periods
  final List<String> _timePeriods = ['This Month', '3 Months', '6 Months', '1 Year'];
  String _selectedPeriod = 'This Month';

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
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadExchangeRates(),
      _loadSpendingData(),
      _loadCategoryData(),
      _loadSubscriptions(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadExchangeRates() async {
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
        
        _exchangeRates = rates.isNotEmpty ? rates : {'USD': 1.0};
      }
    } catch (e) {
      _exchangeRates = {
        'USD': 1.0, 'EUR': 0.856, 'GBP': 0.741, 'INR': 88.1,
        'CAD': 1.37, 'AUD': 1.53, 'JPY': 147.04,
      };
    }
  }

  Future<void> _loadSpendingData() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final data = await firebaseService.getSpendingAnalytics();
      
      setState(() {
        _spendingData = {
          'monthly': _convertCurrency(data['monthly'] ?? 0.0, 'USD', _selectedCurrency),
          'yearly': _convertCurrency(data['yearly'] ?? 0.0, 'USD', _selectedCurrency),
        };
      });
    } catch (e) {
      print('Error loading spending data: $e');
    }
  }

  Future<void> _loadCategoryData() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final data = await firebaseService.getCategorySpending();
      
      final convertedData = <String, double>{};
      for (var entry in data.entries) {
        convertedData[entry.key] = _convertCurrency(entry.value, 'USD', _selectedCurrency);
      }
      
      setState(() => _categoryData = convertedData);
    } catch (e) {
      print('Error loading category data: $e');
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final subs = await firebaseService.getSubscriptions().first;
      setState(() => _subscriptions = subs);
    } catch (e) {
      print('Error loading subscriptions: $e');
    }
  }

  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = _exchangeRates[fromCurrency] ?? 1.0;
    final toRate = _exchangeRates[toCurrency] ?? 1.0;
    
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingScreen() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        'Analytics',
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
      actions: [
        _buildCurrencyDropdown(),
        SizedBox(width: 16),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Overview'),
          Tab(text: 'Categories'),
          Tab(text: 'Trends'),
        ],
      ),
    );
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
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
          items: _currencies.map((currency) => DropdownMenuItem<String>(
            value: currency['code'],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currency['symbol']!,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 6),
                Text(currency['code']!, style: TextStyle(color: Colors.white)),
              ],
            ),
          )).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedCurrency) {
              setState(() => _selectedCurrency = newValue);
              _loadAnalyticsData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading Analytics...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildCategoriesTab(),
        _buildTrendsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final currencySymbol = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(currencySymbol),
          SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(currencySymbol),
          SizedBox(height: 24),

          // Top Subscriptions
          _buildTopSubscriptions(currencySymbol),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(String currencySymbol) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Monthly Spending',
            '$currencySymbol${_spendingData['monthly']?.toStringAsFixed(2) ?? '0.00'}',
            Icons.calendar_month,
            AppColors.primary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Yearly Projection',
            '$currencySymbol${_spendingData['yearly']?.toStringAsFixed(2) ?? '0.00'}',
            Icons.trending_up,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(String currencySymbol) {
    final activeCount = _subscriptions.where((s) => s.isActive).length;
    final inactiveCount = _subscriptions.where((s) => !s.isActive).length;
    final avgCost = _subscriptions.isNotEmpty 
        ? _spendingData['monthly']! / activeCount 
        : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Active', '$activeCount', AppColors.success),
              _buildQuickStat('Inactive', '$inactiveCount', AppColors.error),
              _buildQuickStat(
                'Avg Cost',
                '$currencySymbol${avgCost.toStringAsFixed(2)}',
                AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSubscriptions(String currencySymbol) {
    final sortedSubs = _subscriptions
        .where((s) => s.isActive)
        .toList()
        ..sort((a, b) => b.monthlyEquivalent.compareTo(a.monthlyEquivalent));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Subscriptions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ...sortedSubs.take(5).map((sub) {
            final convertedAmount = _convertCurrency(
              sub.monthlyEquivalent,
              sub.currency,
              _selectedCurrency,
            );
            return _buildSubscriptionItem(sub, convertedAmount, currencySymbol);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(SubscriptionModel sub, double amount, String symbol) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              sub.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  sub.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$symbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categoryData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No category data available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Pie Chart
          Container(
            height: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Category List
          _buildCategoryList(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    final total = _categoryData.values.fold(0.0, (sum, value) => sum + value);
    
    return _categoryData.entries.map((entry) {
      final index = _categoryData.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / total) * 100;
      
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryList() {
    final currencySymbol = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ..._categoryData.entries.map((entry) {
            return _buildCategoryItem(
              entry.key,
              entry.value,
              currencySymbol,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, String symbol) {
    final total = _categoryData.values.fold(0.0, (sum, value) => sum + value);
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$symbol${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          SizedBox(height: 24),

          // Growth Insights
          _buildGrowthInsights(),
          SizedBox(height: 24),

          // Upcoming Renewals
          _buildUpcomingRenewals(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: _timePeriods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrowthInsights() {
    final currencySymbol = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up,
            'Monthly Growth',
            '+12.5%',
            'Compared to last month',
            AppColors.success,
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            Icons.savings,
            'Potential Savings',
            '$currencySymbol${45.20.toStringAsFixed(2)}',
            'By optimizing subscriptions',
            AppColors.secondary,
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            Icons.warning,
            'High Spending',
            'Entertainment',
            '65% of total spending',
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String value, String subtitle, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingRenewals() {
    final upcomingRenewals = _subscriptions
        .where((s) => s.isActive && s.daysUntilBilling <= 7)
        .toList()
        ..sort((a, b) => a.daysUntilBilling.compareTo(b.daysUntilBilling));

    if (upcomingRenewals.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'No upcoming renewals in the next 7 days',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currencySymbol = _currencies
        .firstWhere((c) => c['code'] == _selectedCurrency)['symbol']!;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Renewals (Next 7 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ...upcomingRenewals.map((sub) {
            final convertedAmount = _convertCurrency(
              sub.price,
              sub.currency,
              _selectedCurrency,
            );
            return _buildRenewalItem(sub, convertedAmount, currencySymbol);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRenewalItem(SubscriptionModel sub, double amount, String symbol) {
    final urgencyColor = Helpers.getRenewalUrgencyColor(sub.daysUntilBilling);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: urgencyColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${sub.daysUntilBilling} days • $symbol${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
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
}
