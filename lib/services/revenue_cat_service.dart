import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/constants.dart';

class RevenueCatService {
  static const String _entitlementId = 'premium';
  static const String _monthlyProductId = 'premium_monthly';
  static const String _yearlyProductId = 'premium_yearly';

  static Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration = PurchasesConfiguration(AppConstants.revenueCatApiKey);
      await Purchases.configure(configuration);
      
      // Removed print statement - use debugPrint if needed
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  // Check if user has premium subscription
  static Future<bool> isPremiumUser() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  // Get customer info
  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  // Get available offerings
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  // Get available packages
  static Future<List<Package>> getAvailablePackages() async {
    try {
      Offerings? offerings = await getOfferings();
      return offerings?.current?.availablePackages ?? [];
    } catch (e) {
      debugPrint('Error getting available packages: $e');
      return [];
    }
  }

  // Purchase premium subscription (monthly)
  static Future<bool> purchaseMonthlyPremium() async {
    try {
      Offerings? offerings = await getOfferings();
      Package? monthlyPackage = offerings?.current?.monthly;
      
      if (monthlyPackage != null) {
        CustomerInfo customerInfo = (await Purchases.purchasePackage(monthlyPackage)) as CustomerInfo;
        return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      }
      
      debugPrint('Monthly package not found');
      return false;
    } on PurchasesErrorCode catch (e) {
      debugPrint('Purchase error: ${e.toString()}');
      _handlePurchaseError(e);
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  // Purchase premium subscription (yearly)
  static Future<bool> purchaseYearlyPremium() async {
    try {
      Offerings? offerings = await getOfferings();
      Package? yearlyPackage = offerings?.current?.annual;
      
      if (yearlyPackage != null) {
        CustomerInfo customerInfo = (await Purchases.purchasePackage(yearlyPackage)) as CustomerInfo;
        return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      }
      
      debugPrint('Yearly package not found');
      return false;
    } on PurchasesErrorCode catch (e) {
      debugPrint('Purchase error: ${e.toString()}');
      _handlePurchaseError(e);
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  // Purchase specific package
  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(package)) as CustomerInfo;
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PurchasesErrorCode catch (e) {
      debugPrint('Purchase error: ${e.toString()}');
      _handlePurchaseError(e);
      return false;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  // Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  // FIXED: Get premium expiry date - proper return type
  static Future<String?> getPremiumExpiryDate() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      EntitlementInfo? premiumEntitlement = customerInfo.entitlements.all[_entitlementId];
      
      if (premiumEntitlement?.isActive == true) {
        return premiumEntitlement?.expirationDate;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting premium expiry date: $e');
      return null;
    }
  }

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.activeSubscriptions.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking active subscription: $e');
      return false;
    }
  }

  // FIXED: Get subscription status details - removed invalid properties
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      EntitlementInfo? premiumEntitlement = customerInfo.entitlements.all[_entitlementId];
      
      return {
        'isPremium': premiumEntitlement?.isActive ?? false,
        'willRenew': premiumEntitlement?.willRenew ?? false,
        'periodType': premiumEntitlement?.periodType.toString() ?? 'unknown',
        'productIdentifier': premiumEntitlement?.productIdentifier ?? '',
        'purchaseDate': premiumEntitlement?.latestPurchaseDate,
        'expirationDate': premiumEntitlement?.expirationDate,
        // REMOVED: 'isInGracePeriod' property as it doesn't exist
        'store': premiumEntitlement?.store.toString() ?? 'unknown',
      };
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      return {
        'isPremium': false,
        'willRenew': false,
        'periodType': 'unknown',
        'productIdentifier': '',
        'purchaseDate': null,
        'expirationDate': null,
        'store': 'unknown',
      };
    }
  }

  // Set user attributes for analytics
  static Future<void> setUserAttributes(String userId, String email) async {
    try {
      await Purchases.logIn(userId);
      await Purchases.setEmail(email);
    } catch (e) {
      debugPrint('Error setting user attributes: $e');
    }
  }

  // Log out user
  static Future<void> logOutUser() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Error logging out user: $e');
    }
  }

  // Handle purchase errors
  static void _handlePurchaseError(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        debugPrint('Purchase was cancelled by user');
        break;
      case PurchasesErrorCode.purchaseNotAllowedError:
        debugPrint('Purchase not allowed');
        break;
      case PurchasesErrorCode.purchaseInvalidError:
        debugPrint('Purchase invalid');
        break;
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        debugPrint('Product not available for purchase');
        break;
      case PurchasesErrorCode.networkError:
        debugPrint('Network error during purchase');
        break;
      case PurchasesErrorCode.receiptAlreadyInUseError:
        debugPrint('Receipt already in use');
        break;
      case PurchasesErrorCode.missingReceiptFileError:
        debugPrint('Missing receipt file');
        break;
      default:
        debugPrint('Unknown purchase error: ${errorCode.toString()}');
    }
  }

  // Get pricing information
  static Future<Map<String, String>> getPricingInfo() async {
    try {
      List<Package> packages = await getAvailablePackages();
      Map<String, String> pricing = {};
      
      for (Package package in packages) {
        if (package.identifier == _monthlyProductId) {
          pricing['monthly'] = package.storeProduct.priceString;
        } else if (package.identifier == _yearlyProductId) {
          pricing['yearly'] = package.storeProduct.priceString;
        }
      }
      
      return pricing;
    } catch (e) {
      debugPrint('Error getting pricing info: $e');
      return {};
    }
  }

  // Check if restore is available
  static Future<bool> canMakePayments() async {
    try {
      return await Purchases.canMakePayments();
    } catch (e) {
      debugPrint('Error checking if payments can be made: $e');
      return false;
    }
  }
}
