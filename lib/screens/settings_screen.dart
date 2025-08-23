import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserModel? _currentUser;
  bool _isPremium = false;
  bool _notificationsEnabled = true;
  Map<String, dynamic> _subscriptionStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
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

  Future<void> _loadUserData() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final user = await firebaseService.getUserData();
      final isPremium = await RevenueCatService.isPremiumUser();
      final subscriptionStatus = await RevenueCatService.getSubscriptionStatus();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isPremium = isPremium;
          _subscriptionStatus = subscriptionStatus;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Section
                    _buildProfileSection(),
                    
                    SizedBox(height: 24),
                    
                    // Premium Section
                    if (!_isPremium) _buildPremiumPromotionCard(),
                    if (_isPremium) _buildPremiumStatusCard(),
                    
                    SizedBox(height: 24),
                    
                    // Settings Sections
                    _buildSettingsSection(),
                    
                    SizedBox(height: 32),
                    
                    // Logout Button
                    _buildLogoutButton(),
                    
                    SizedBox(height: 20),
                    
                    // App Info
                    _buildAppInfo(),
                  ],
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
        'Settings',
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

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.name ?? 'User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPremium ? AppColors.secondary : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isPremium ? 'Premium User' : 'Free Plan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isPremium ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPromotionCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
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
              Icon(Icons.star, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Unlock unlimited subscriptions, 2 years of history, and advanced analytics.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _upgradeToPremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Upgrade Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusCard() {
    final expiryDate = _subscriptionStatus['expirationDate'] as DateTime?;
    final willRenew = _subscriptionStatus['willRenew'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
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
              Icon(Icons.star, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Premium Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (expiryDate != null) ...[
            Text(
              willRenew 
                  ? 'Renews on ${Helpers.formatDate(expiryDate)}'
                  : 'Expires on ${Helpers.formatDate(expiryDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 8),
          ],
          Text(
            'Enjoying unlimited subscriptions and premium features!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _managePremiumSubscription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Manage Subscription'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildSettingsGroup(
          'General',
          [
            _buildSettingsTile(
              Icons.notifications_outlined,
              'Notifications',
              'Manage notification preferences',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: AppColors.primary,
              ),
            ),
            _buildSettingsTile(
              Icons.analytics_outlined,
              'Analytics',
              'View spending insights',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Analytics coming soon!')),
                );
              },
            ),
            _buildSettingsTile(
              Icons.history,
              'History',
              'View subscription history',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('History coming soon!')),
                );
              },
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        _buildSettingsGroup(
          'Support',
          [
            _buildSettingsTile(
              Icons.help_outline,
              'Help & Support',
              'Get help with the app',
              onTap: _showHelpDialog,
            ),
            _buildSettingsTile(
              Icons.info_outline,
              'About',
              'App version and information',
              onTap: _showAboutDialog,
            ),
            _buildSettingsTile(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'Read our privacy policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Privacy Policy coming soon!')),
                );
              },
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        _buildSettingsGroup(
          'Account',
          [
            _buildSettingsTile(
              Icons.person_outline,
              'Edit Profile',
              'Update your personal information',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit Profile coming soon!')),
                );
              },
            ),
            _buildSettingsTile(
              Icons.security,
              'Change Password',
              'Update your account password',
              onTap: _changePassword,
            ),
            if (_isPremium)
              _buildSettingsTile(
                Icons.restore,
                'Restore Purchases',
                'Restore your premium subscription',
                onTap: _restorePurchases,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, color: AppColors.textSecondary) : null),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return DangerButton(
      text: 'Logout',
      onPressed: _logout,
      icon: Icons.logout,
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          '${AppStrings.appName} v1.0.0',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Made with ❤️ for subscription management',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _upgradeToPremium() async {
    try {
      final success = await RevenueCatService.purchaseMonthlyPremium();
      if (success) {
        await _loadUserData();
        _showSuccessSnackBar('Welcome to Premium! 🎉');
      } else {
        _showErrorSnackBar('Purchase was cancelled or failed');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upgrade to Premium');
    }
  }

  void _managePremiumSubscription() {
    // TODO: Open subscription management screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscription management coming soon!')),
    );
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (value) {
      NotificationService.requestPermissions();
      _showInfoSnackBar('Notifications enabled');
    } else {
      NotificationService.cancelAllNotifications();
      _showInfoSnackBar('Notifications disabled');
    }
  }

  void _changePassword() {
    // TODO: Implement change password functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change password coming soon!')),
    );
  }

  Future<void> _restorePurchases() async {
    try {
      final success = await RevenueCatService.restorePurchases();
      if (success) {
        await _loadUserData();
        _showSuccessSnackBar('Purchases restored successfully!');
      } else {
        _showInfoSnackBar('No purchases found to restore');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to restore purchases');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with SubVault?'),
            SizedBox(height: 16),
            Text('• Email: support@subvault.app'),
            Text('• Website: www.subvault.app/help'),
            Text('• FAQ: Available in the app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.account_balance_wallet, size: 48, color: AppColors.primary),
      children: [
        Text('${AppStrings.tagline}\n'),
        Text('SubVault helps you track and manage all your subscriptions in one place. Never miss a renewal date again!'),
      ],
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          DangerButton(
            text: 'Logout',
            width: 80,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebaseService = Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.signOut();
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        _showErrorSnackBar('Failed to logout');
      }
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
