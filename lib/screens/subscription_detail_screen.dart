import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_button.dart';
import 'add_subscription_screen.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;

  const SubscriptionDetailScreen({
    Key? key,
    required this.subscription,
  }) : super(key: key);

  @override
  _SubscriptionDetailScreenState createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
              child: _buildContent(),
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
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
      ),
      title: Text(
        widget.subscription.name,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _editSubscription,
          icon: Icon(Icons.edit, color: AppColors.primary),
          tooltip: 'Edit Subscription',
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Logo and Main Info
          _buildHeaderCard(),
          SizedBox(height: 24),

          // Billing Information
          _buildBillingCard(),
          SizedBox(height: 24),

          // Additional Details
          if (widget.subscription.description?.isNotEmpty == true ||
              widget.subscription.website?.isNotEmpty == true)
            _buildDetailsCard(),

          if (widget.subscription.description?.isNotEmpty == true ||
              widget.subscription.website?.isNotEmpty == true)
            SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Center(
    child:  Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children : [
          _buildServiceIcon(),
          SizedBox(height: 16),

          // Service Name
          Text(
            widget.subscription.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),

          // Category
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.subscription.category,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Price
          Text(
            widget.subscription.formattedPrice,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'per ${widget.subscription.billingCycle.name}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
       ),
      ),
    );
  }

  Widget _buildServiceIcon() {
    if (widget.subscription.iconUrl.isEmpty) {
      return _buildFallbackIcon();
    }

    if (widget.subscription.iconUrl.startsWith('http')) {
      return Container(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            widget.subscription.iconUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          ),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icons/${widget.subscription.iconUrl}',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          ),
        ),
      );
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _getCategoryIcon(),
        color: Colors.white,
        size: 40,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.subscription.category.toLowerCase()) {
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

  Widget _buildBillingCard() {
    final daysLeft = widget.subscription.daysUntilBilling;
    final renewalColor = Helpers.getRenewalUrgencyColor(daysLeft);

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
            'Billing Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          _buildInfoRow(
            Icons.attach_money,
            'Price',
            widget.subscription.formattedPrice,
          ),
          SizedBox(height: 12),

          _buildInfoRow(
            Icons.schedule,
            'Billing Cycle',
            Helpers.formatBillingCycle(widget.subscription.billingCycle.name),
          ),
          SizedBox(height: 12),

          _buildInfoRow(
            Icons.calendar_today,
            'Start Date',
            Helpers.formatDate(widget.subscription.startDate),
          ),
          SizedBox(height: 12),

          _buildInfoRow(
            Icons.update,
            'Next Billing',
            Helpers.formatDate(widget.subscription.nextBilling),
            valueColor: renewalColor,
          ),
          SizedBox(height: 16),

          // Renewal Status Badge
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: renewalColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: renewalColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: renewalColor, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getRenewalText(daysLeft),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: renewalColor,
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

  Widget _buildDetailsCard() {
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
            'Additional Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          if (widget.subscription.description?.isNotEmpty == true) ...[
            _buildInfoRow(
              Icons.description,
              'Description',
              widget.subscription.description!,
            ),
            if (widget.subscription.website?.isNotEmpty == true)
              SizedBox(height: 12),
          ],

          if (widget.subscription.website?.isNotEmpty == true)
            _buildInfoRow(
              Icons.link,
              'Website',
              widget.subscription.website!,
              isLink: true,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isOverdue = widget.subscription.isOverdue;

    return Column(
      children: [
        if (isOverdue) ...[
          PrimaryButton(
            text: 'Mark as Paid',
            onPressed: _markAsPaid,
            icon: Icons.payment,
            backgroundColor: AppColors.success,
          ),
          SizedBox(height: 16),
        ],
        PrimaryButton(
          text: 'Edit Subscription',
          onPressed: _editSubscription,
          icon: Icons.edit,
        ),
        SizedBox(height: 16),
        DangerButton(
          text: 'Delete Subscription',
          onPressed: _deleteSubscription,
          icon: Icons.delete,
        ),
      ],
    );
  }

  String _getRenewalText(int daysLeft) {
    // if (daysLeft < 0) {
    //   return 'Overdue by ${daysLeft.abs()} days';
    // } else if (daysLeft == 0) {
    //   return 'Renews today';
    // } else if (daysLeft == 1) {
    //   return 'Renews tomorrow';
    // } else if (daysLeft <= 7) {
    //   return 'Renews in $daysLeft days';
    // } else {
    //   return 'Renews in $daysLeft days';
    // }
    return widget.subscription.statusText;
  }

  void _editSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubscriptionScreen(
          editingSubscription: widget.subscription,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Return to home screen with refresh signal
        Navigator.pop(context, true);
      }
    });
  }

  Future<void> _markAsPaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Paid'),
        content: Text('Mark ${widget.subscription.name} as paid and renew for the next billing cycle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Mark Paid',
            width: 120,
            height: 40,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebaseService = Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.markSubscriptionAsPaid(widget.subscription.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.subscription.name} marked as paid successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Return to home screen with refresh signal
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as paid: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Subscription'),
        content: Text('Are you sure you want to delete ${widget.subscription.name}?'),
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
        final firebaseService = Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.deleteSubscription(widget.subscription.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.subscription.name} deleted successfully')),
        );
        
        // Return to home screen with refresh signal
        Navigator.pop(context, true);
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
}
