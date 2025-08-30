import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'notification_service.dart';

// Top-level function for background messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // Handle background notification here
}

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.uid;

  // Initialize Firebase services
  static Future<void> initializeFirebase() async {
    try {
      await _initializeFirebaseMessaging();
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  // Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      
      // Get FCM token for this device
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message notification: ${message.notification?.title}');
          // Show local notification using our NotificationService
          NotificationService.showNotification(
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? 'You have a new message',
          );
        }
      });
      
      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        debugPrint('Message data: ${message.data}');
        // TODO: Navigate to specific screen based on message data
      });
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }
  }

  // Authentication
  Future<UserCredential?> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await result.user?.updateDisplayName(name);
      
      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!, name);
      }
      
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      throw 'An unexpected error occurred during sign up';
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw 'An unexpected error occurred during sign in';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw 'Failed to sign out';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'user-not-found':
        return 'No user found for this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      default:
        return e.message ?? 'Authentication failed';
    }
  }

  // User Management
  Future<void> _createUserDocument(User user, String name) async {
    try {
      final userModel = UserModel(
        id: user.uid,
        email: user.email!,
        name: name,
        createdAt: DateTime.now(),
        isPremium: false,
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toFirestore(),
        SetOptions(merge: true), // Merge to avoid overwriting existing data
      );
      
      // Store FCM token for push notifications
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Create user document error: $e');
      throw 'Failed to create user profile';
    }
  }

  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
          
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get user data error: $e');
      return null;
    }
  }

  Future<void> updateUserData(UserModel user) async {
    if (currentUser == null) throw 'User not authenticated';
    
    try {
      await _firestore.collection('users').doc(currentUser!.uid).update(
        user.toFirestore()
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Update user data error: $e');
      throw 'Failed to update user profile';
    }
  }

  // Subscription Management
  Future<bool> canAddSubscription() async {
    if (currentUser == null) return false;

    try {
      // Check if user is premium
      UserModel? user = await getUserData();
      if (user?.isPremiumActive == true) return true;

      // Count active subscriptions for free users
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count! < AppConstants.freeSubscriptionLimit;
    } catch (e) {
      debugPrint('Can add subscription error: $e');
      return false;
    }
  }

  Future<String?> addSubscription(SubscriptionModel subscription) async {
    if (currentUser == null) throw 'User not authenticated';
    
    try {
      // Check if user can add subscription
      bool canAdd = await canAddSubscription();
      if (!canAdd) {
        throw 'Subscription limit reached. Upgrade to Premium for unlimited subscriptions.';
      }

      // Add subscription to Firestore
      await _validateUniqueSubscriptionName(subscription.name, subscription.id);
      DocumentReference doc = await _firestore.collection('subscriptions').add(
        subscription.copyWith(userId: currentUser!.uid).toFirestore()
      );

      // Schedule notifications for the new subscription
      await NotificationService.scheduleRenewalReminder(
        subscription.copyWith(id: doc.id, userId: currentUser!.uid)
      );
      
      notifyListeners();
      return doc.id;
    } catch (e) {
      debugPrint('Add subscription error: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String id, SubscriptionModel subscription) async {
    if (currentUser == null) throw 'User not authenticated';
    
    try {
      await _validateUniqueSubscriptionName(subscription.name, id);
      await _firestore.collection('subscriptions').doc(id).update(
        subscription.toFirestore()
      );
      
      // Update notifications
      await NotificationService.cancelSubscriptionNotifications(id);
      if (subscription.isActive) {
        await NotificationService.scheduleRenewalReminder(subscription);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Update subscription error: $e');
      throw 'Failed to update subscription';
    }
  }

  Future<void> deleteSubscription(String id) async {
    if (currentUser == null) throw 'User not authenticated';
    
    try {
      await _firestore.collection('subscriptions').doc(id).delete();
      
      // Cancel notifications
      await NotificationService.cancelSubscriptionNotifications(id);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Delete subscription error: $e');
      throw 'Failed to delete subscription';
    }
  }

  Future<void> toggleSubscriptionStatus(String id, bool isActive) async {
    if (currentUser == null) throw 'User not authenticated';
    
    try {
      await _firestore.collection('subscriptions').doc(id).update({
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      if (!isActive) {
        await NotificationService.cancelSubscriptionNotifications(id);
      } else {
        // Re-schedule notifications if reactivated
        SubscriptionModel? subscription = await getSubscription(id);
        if (subscription != null) {
          await NotificationService.scheduleRenewalReminder(subscription);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Toggle subscription status error: $e');
      throw 'Failed to update subscription status';
    }
  }

  // Private helper method to check for duplicate subscription names
  Future<void> _validateUniqueSubscriptionName(String name, [String? excludeId]) async {
    if (currentUser == null) return;
    
    try {
      final trimmedName = name.trim().toLowerCase();
      
      Query query = _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true);
      
      QuerySnapshot snapshot = await query.get();
      
      // Check if any existing subscription has the same name
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingName = (data['name'] as String? ?? '').trim().toLowerCase();
        
        // Skip if this is the same document we're updating
        if (excludeId != null && doc.id == excludeId) continue;
        
        if (existingName == trimmedName) {
          throw Exception('A subscription with the name "$name" already exists.');
        }
      }
    } catch (e) {
      debugPrint('Validation error: $e');
      rethrow;
    }
  }


    Stream<List<SubscriptionModel>> getSubscriptions({bool activeOnly = true}) {
      if (currentUser == null) return Stream.value([]);
      
      Query query = _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid);
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      return query
          .orderBy('nextBilling')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList())
          .handleError((error) {
            debugPrint('Get subscriptions stream error: $error');
            return <SubscriptionModel>[];
          });
    }

  Future<SubscriptionModel?> getSubscription(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('subscriptions').doc(id).get();
      if (doc.exists) {
        return SubscriptionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get subscription error: $e');
      return null;
    }
  }

  // Analytics with better error handling
  Future<Map<String, double>> getSpendingAnalytics() async {
    if (currentUser == null) return {'monthly': 0.0, 'yearly': 0.0};

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      double monthlyTotal = 0.0;
      double yearlyTotal = 0.0;

      for (var doc in snapshot.docs) {
        try {
          SubscriptionModel subscription = SubscriptionModel.fromFirestore(doc);
          monthlyTotal += subscription.monthlyEquivalent;
          yearlyTotal += subscription.monthlyEquivalent * 12;
        } catch (e) {
          debugPrint('Error processing subscription ${doc.id}: $e');
          // Continue processing other subscriptions
        }
      }

      return {
        'monthly': monthlyTotal,
        'yearly': yearlyTotal,
      };
    } catch (e) {
      debugPrint('Get spending analytics error: $e');
      return {'monthly': 0.0, 'yearly': 0.0};
    }
  }

  Future<List<SubscriptionModel>> getUpcomingRenewals({int days = 30}) async {
    if (currentUser == null) return [];

    try {
      final futureDate = DateTime.now().add(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .where('nextBilling', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
          .orderBy('nextBilling')
          .limit(50) // Limit results for performance
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return SubscriptionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error processing upcoming renewal ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SubscriptionModel>()
          .toList();
    } catch (e) {
      debugPrint('Get upcoming renewals error: $e');
      return [];
    }
  }

  Future<Map<String, double>> getCategorySpending() async {
    if (currentUser == null) return {};

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, double> categorySpending = {};

      for (var doc in snapshot.docs) {
        try {
          SubscriptionModel subscription = SubscriptionModel.fromFirestore(doc);
          String category = subscription.category;
          double monthlyAmount = subscription.monthlyEquivalent;
          
          categorySpending[category] = (categorySpending[category] ?? 0) + monthlyAmount;
        } catch (e) {
          debugPrint('Error processing category spending for ${doc.id}: $e');
        }
      }

      return categorySpending;
    } catch (e) {
      debugPrint('Get category spending error: $e');
      return {};
    }
  }

  // Enhanced history management
  Future<void> addSubscriptionHistory(SubscriptionModel subscription) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('subscription_history').add({
        'userId': currentUser!.uid,
        'subscriptionId': subscription.id,
        'subscriptionName': subscription.name,
        'amount': subscription.price,
        'currency': subscription.currency,
        'billingCycle': subscription.billingCycle.name,
        'paidDate': FieldValue.serverTimestamp(),
        'nextBilling': Timestamp.fromDate(subscription.nextBilling),
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Add subscription history error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptionHistory({bool isPremium = false}) async {
    if (currentUser == null) return [];

    try {
      final monthsLimit = isPremium ? AppConstants.premiumHistoryMonths : AppConstants.freeHistoryMonths;
      final cutoffDate = DateTime.now().subtract(Duration(days: 30 * monthsLimit));
      final resultLimit = isPremium ? 1000 : 50;

      QuerySnapshot snapshot = await _firestore
          .collection('subscription_history')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('paidDate', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('paidDate', descending: true)
          .limit(resultLimit)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Get subscription history error: $e');
      return [];
    }
  }

  // Utility Methods with improved performance
  Future<int> getActiveSubscriptionCount() async {
    if (currentUser == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Get active subscription count error: $e');
      return 0;
    }
  }

  // Enhanced batch update with better error handling
  Future<void> updateAllRenewalDates() async {
    if (currentUser == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      WriteBatch batch = _firestore.batch();
      List<Future<void>> historyTasks = [];
      int batchCount = 0;
      
      for (var doc in snapshot.docs) {
        try {
          SubscriptionModel subscription = SubscriptionModel.fromFirestore(doc);
          
          if (subscription.nextBilling.isBefore(DateTime.now())) {
            DateTime newNextBilling = Helpers.calculateNextBilling(
              subscription.startDate, 
              subscription.billingCycle.name
            );
            
            batch.update(doc.reference, {
              'nextBilling': Timestamp.fromDate(newNextBilling),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            
            // Add to history (async)
            historyTasks.add(addSubscriptionHistory(subscription));
            batchCount++;
            
            // Commit batch if it gets too large (Firestore limit is 500)
            if (batchCount >= 400) {
              await batch.commit();
              batch = _firestore.batch();
              batchCount = 0;
            }
          }
        } catch (e) {
          debugPrint('Error processing renewal for ${doc.id}: $e');
        }
      }
      
      // Commit remaining updates
      if (batchCount > 0) {
        await batch.commit();
      }
      
      // Wait for all history updates to complete
      await Future.wait(historyTasks);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Update all renewal dates error: $e');
    }
  }

  // FCM Token management
  Future<void> updateFCMToken() async {
    if (currentUser == null) return;
    
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Update FCM token error: $e');
    }
  }
}