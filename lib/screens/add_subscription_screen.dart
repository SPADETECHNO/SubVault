import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/revenue_cat_service.dart';
import '../models/subscription_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final SubscriptionModel? editingSubscription;

  const AddSubscriptionScreen({
    Key? key,
    this.editingSubscription,
  }) : super(key: key);

  @override
  _AddSubscriptionScreenState createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = AppConstants.categories.first;
  String _selectedCurrency = 'USD';
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  DateTime _selectedStartDate = DateTime.now();
  String _selectedIconUrl = '';
  bool _isLoading = false;
  bool _isPremium = false;
  int _currentSubscriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    _prefillDataIfEditing();
    _detectUserCurrency();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _detectUserCurrency() {
    try {
      final locale = Localizations.localeOf(context);
      final countryCode = locale.countryCode;
      
      final currencyMap = {
        'US': 'USD', 'GB': 'GBP', 'IN': 'INR', 'CA': 'CAD',
        'AU': 'AUD', 'JP': 'JPY', 'DE': 'EUR', 'FR': 'EUR',
        'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR', 'AT': 'EUR',
      };
      
      setState(() {
        _selectedCurrency = currencyMap[countryCode] ?? 'USD';
      });
    } catch (e) {
      // Keep default USD
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final isPremium = await RevenueCatService.isPremiumUser();
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final count = await firebaseService.getActiveSubscriptionCount();
      
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _currentSubscriptionCount = count;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _prefillDataIfEditing() {
    if (widget.editingSubscription != null) {
      final sub = widget.editingSubscription!;
      _nameController.text = sub.name;
      _priceController.text = sub.price.toString();
      _descriptionController.text = sub.description ?? '';
      _websiteController.text = sub.website ?? '';
      _selectedCategory = sub.category;
      _selectedBillingCycle = sub.billingCycle;
      _selectedStartDate = sub.startDate;
      _selectedIconUrl = sub.iconUrl;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check subscription limit for free users
    if (!_isPremium && 
        _currentSubscriptionCount >= AppConstants.freeSubscriptionLimit &&
        widget.editingSubscription == null) {
      return _buildUpgradeScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Services Section
                      if (widget.editingSubscription == null) _buildPopularServices(),
                      
                      // Custom Form Section
                      _buildCustomFormSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        widget.editingSubscription != null 
            ? 'Edit Subscription' 
            : 'Add Subscription',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildUpgradeScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                size: 80,
                color: AppColors.secondary,
              ),
              SizedBox(height: 24),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'You\'ve reached the limit of ${AppConstants.freeSubscriptionLimit} subscriptions.\nUpgrade to Premium for unlimited subscriptions!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),
              _buildFeaturesList(),
              SizedBox(height: 32),
              PrimaryButton(
                text: 'Upgrade to Premium',
                onPressed: _upgradeToPremium,
                icon: Icons.star,
              ),
              SizedBox(height: 16),
              SecondaryButton(
                text: 'Maybe Later',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Unlimited subscriptions',
      '2 years of history',
      'Advanced analytics',
      'Priority support',
    ];

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
        children: features.map((feature) => Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text(
                feature,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPopularServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Quick add from popular subscription services',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.popularServices.length,
            itemBuilder: (context, index) {
              final service = AppConstants.popularServices[index];
              return _buildPopularServiceCard(service);
            },
          ),
        ),
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or create custom',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPopularServiceCard(Map<String, String> service) {
    return GestureDetector(
      onTap: () => _selectPopularService(service),
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icons/${service['icon']!}',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getServiceIcon(service['name']!),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              service['name']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final currencies = [
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
      {'code': 'CAD', 'symbol': 'C\$', 'name': 'Dollar'},
      {'code': 'AUD', 'symbol': 'A\$', 'name': 'Dollar'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanse Yen'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: currencies.map((currency) => DropdownMenuItem(
                value: currency['code'],
                child: Row(
                  children: [
                    Text(
                      currency['symbol']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency['code']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            currency['name']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCurrency = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol(String currencyCode) {
    final symbols = {
      'USD': '\$',
      'EUR': '€', 
      'GBP': '£',
      'INR': '₹',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'JPY': '¥',
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  Widget _buildCustomFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service Name
        CustomTextField(
          label: 'Service Name',
          hintText: 'e.g., Netflix, Spotify, etc.',
          controller: _nameController,
          prefixIcon: Icons.subscriptions,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the service name';
            }
            if (value.trim().length < 2) {
              return 'Service name must be at least 2 characters';
            }
            if (value.trim().length > 50) {
              return 'Service name is too long';
            }
            return null;
          },
        ),
        
        SizedBox(height: 20),
        
        // Price and Billing Cycle Row
        Row(
          children: [ 
            Expanded(
              flex: 2,
              child: _buildCurrencySelector(),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: PriceTextField(
                controller: _priceController,
                prefixText: _getCurrencySymbol(_selectedCurrency),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildBillingCycleSelector(),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        // Category Selector
        _buildCategorySelector(),
        
        SizedBox(height: 20),
        
        // Start Date Selector
        _buildStartDateSelector(),
        
        SizedBox(height: 20),
        
        // Description (Optional)
        CustomTextField(
          label: 'Description (Optional)',
          hintText: 'Add notes about this subscription',
          controller: _descriptionController,
          prefixIcon: Icons.description,
          maxLines: 2,
        ),
        
        SizedBox(height: 20),
        
        // Website (Optional)
        CustomTextField(
          label: 'Website (Optional)',
          hintText: 'https://example.com',
          controller: _websiteController,
          prefixIcon: Icons.link,
          keyboardType: TextInputType.url,
        ),
        
        SizedBox(height: 40),
        
        // Save Button
        PrimaryButton(
          text: widget.editingSubscription != null ? 'Update Subscription' : 'Add Subscription',
          onPressed: _saveSubscription,
          isLoading: _isLoading,
          icon: widget.editingSubscription != null ? Icons.update : Icons.add,
        ),
      ],
    );
  }

  Widget _buildBillingCycleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing Cycle',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BillingCycle>(
              value: _selectedBillingCycle,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: BillingCycle.values.map((cycle) => DropdownMenuItem(
                value: cycle,
                child: Text(
                  Helpers.formatBillingCycle(cycle.name),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              )).toList(),
              onChanged: (BillingCycle? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedBillingCycle = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: AppConstants.categories.map((category) => DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _selectStartDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                SizedBox(width: 12),
                Text(
                  Helpers.formatDate(_selectedStartDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Spacer(),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName.toLowerCase()) {
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      case 'jiohotstar':
        return Icons.movie_creation;
      case 'youtube premium':
        return Icons.play_circle;
      case 'amazon prime':
        return Icons.shopping_bag;
      case 'adobe creative':
        return Icons.design_services;
      default:
        return Icons.apps;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'entertainment':
        return Icons.movie;
      case 'music':
        return Icons.music_note;
      case 'productivity':
        return Icons.work;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health & fitness':
        return Icons.fitness_center;
      case 'news':
        return Icons.article;
      case 'education':
        return Icons.school;
      case 'gaming':
        return Icons.games;
      case 'finance':
        return Icons.account_balance;
      default:
        return Icons.apps;
    }
  }

  void _selectPopularService(Map<String, String> service) {
    setState(() {
      _nameController.text = service['name']!;
      _selectedCategory = service['category']!;
      _selectedIconUrl = service['icon']!;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final price = double.parse(_priceController.text);
      
      final nextBilling = Helpers.calculateNextBilling(
        _selectedStartDate,
        _selectedBillingCycle.name,
      );

      final subscription = SubscriptionModel(
        id: widget.editingSubscription?.id ?? '',
        userId: firebaseService.currentUserId!,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        currency: _selectedCurrency,
        price: price,
        billingCycle: _selectedBillingCycle,
        nextBilling: nextBilling,
        startDate: _selectedStartDate,
        iconUrl: _selectedIconUrl,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        createdAt: widget.editingSubscription?.createdAt ?? DateTime.now(),
      );

      if (widget.editingSubscription != null) {
        await firebaseService.updateSubscription(
          widget.editingSubscription!.id, 
          subscription
        );
        _showSuccessSnackBar('Subscription updated successfully!');
      } else {
        await firebaseService.addSubscription(subscription);
        _showSuccessSnackBar('Subscription added successfully!');
      }

      Navigator.pop(context, true);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('already exists')) {
        _showErrorSnackBar('A subscription with this name already exists. Please choose a different name.');
      } else if (errorMessage.contains('Subscription limit reached')) {
        _showErrorSnackBar('You\'ve reached your subscription limit. Upgrade to Premium for unlimited subscriptions.');
      } else {
        _showErrorSnackBar('Failed to save subscription. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _upgradeToPremium() async {
    try {
      final success = await RevenueCatService.purchaseMonthlyPremium();
      if (success) {
        setState(() {
          _isPremium = true;
        });
        _showSuccessSnackBar('Welcome to Premium! 🎉');
      } else {
        _showErrorSnackBar('Purchase was cancelled or failed');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upgrade to Premium');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
