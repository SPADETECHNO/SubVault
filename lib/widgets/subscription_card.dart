import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionModel subscription;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onMarkPaid;
  final bool showActions;
  final bool isCompact;

  const SubscriptionCard({
    Key? key,
    required this.subscription,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onMarkPaid,
    this.showActions = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: subscription.isRenewalUrgent 
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            // Icon
            _buildServiceIcon(),
            SizedBox(width: 12),
            
            // Name and Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subscription.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subscription.formattedPrice,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Renewal Info
        _buildRenewalInfo(),
        
        if (showActions) ...[
          SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        // Icon
        _buildServiceIcon(size: 40),
        SizedBox(width: 10),
        
        // Info
        Expanded(
          child: SizedBox(
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Service name at the top
                Text(
                  subscription.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                Row(
                  children: [
                    Text(
                      subscription.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        ' • ${subscription.formattedBillingCycle}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Days until renewal
        _buildRenewalBadge(),
      ],
    );
  }

  Widget _buildServiceIcon({double size = 50}) {
    if (subscription.iconUrl.isEmpty) {
      return _buildFallbackIcon(size);
    }
    if (subscription.iconUrl.startsWith('http')) {
      // Network image
      return Container(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            subscription.iconUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(size);
            },
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/icons/${subscription.iconUrl}',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(size);
            },
          ),
        ),
      );
    }
  }

  Widget _buildFallbackIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Icon(
        _getCategoryIcon(),
        color: AppColors.primary,
        size: size * 0.5,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (subscription.category.toLowerCase()) {
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

  Widget _buildRenewalInfo() {
    final daysLeft = subscription.daysUntilBilling;
    final renewalColor = Helpers.getRenewalUrgencyColor(daysLeft);
    
    return Container(
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
          Icon(
            Icons.schedule,
            color: renewalColor,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRenewalText(daysLeft),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: renewalColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  // 'Last billing: ${Helpers.formatDate(subscription.lastBilling)}', 
                  'Next billing: ${Helpers.formatDate(subscription.nextBilling)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: renewalColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subscription.formattedBillingCycle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalBadge() {
    final daysLeft = subscription.daysUntilBilling;
    final renewalColor = Helpers.getRenewalUrgencyColor(daysLeft);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renewalColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: renewalColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        daysLeft == 0 
            ? 'Today'
            : daysLeft == 1 
                ? '1 day'
                : '$daysLeft days',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: renewalColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isOverdue = subscription.isOverdue;

    return Row(
      children: [
        // Toggle Status
        // Expanded(
        //   child: OutlinedButton.icon(
        //     onPressed: onToggleStatus,
        //     icon: Icon(
        //       subscription.isActive ? Icons.pause : Icons.play_arrow,
        //       size: 16,
        //     ),
        //     label: Text(
        //       subscription.isActive ? 'Pause' : 'Resume',
        //       style: TextStyle(fontSize: 12),
        //     ),
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: subscription.isActive 
        //           ? AppColors.secondary 
        //           : AppColors.success,
        //       side: BorderSide(
        //         color: subscription.isActive 
        //             ? AppColors.secondary 
        //             : AppColors.success,
        //       ),
        //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //     ),
        //   ),
        // ),

        if (subscription.isOverdue && onMarkPaid != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMarkPaid,
              icon: Icon(Icons.payment, size: 16),
              label: Text('Paid', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: BorderSide(color: AppColors.success),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        SizedBox(width: 8),
        ],
        
        // Edit
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: Icon(Icons.edit, size: 16),
            label: Text('Edit', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        
        SizedBox(width: 8),
        
        // Delete
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete, size: 16),
            label: Text('Delete', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
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
    return subscription.statusText;
  }
}

// Compact version for lists
class CompactSubscriptionCard extends StatelessWidget {
  final SubscriptionModel subscription;
  final VoidCallback? onTap;

  const CompactSubscriptionCard({
    Key? key,
    required this.subscription,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SubscriptionCard(
      subscription: subscription,
      onTap: onTap,
      showActions: false,
      isCompact: true,
    );
  }
}

// Summary card for dashboard
class SubscriptionSummaryCard extends StatelessWidget {
  final int totalSubscriptions;
  final double monthlySpending;
  final double yearlySpending;
  final int upcomingRenewals;
  final VoidCallback? onViewAll;

  const SubscriptionSummaryCard({
    Key? key,
    required this.totalSubscriptions,
    required this.monthlySpending,
    required this.yearlySpending,
    required this.upcomingRenewals,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                'Your Subscriptions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  totalSubscriptions.toString(),
                  Icons.apps,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Monthly',
                  Helpers.formatCurrency(monthlySpending),
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Yearly',
                  Helpers.formatCurrency(yearlySpending),
                  Icons.calendar_view_month,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Upcoming',
                  upcomingRenewals.toString(),
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
