import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? premiumExpiresAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.isPremium = false,
    required this.createdAt,
    this.premiumExpiresAt,
    this.profileImageUrl,
    this.preferences,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      isPremium: data['isPremium'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      premiumExpiresAt: data['premiumExpiresAt'] != null
          ? (data['premiumExpiresAt'] as Timestamp).toDate()
          : null,
      profileImageUrl: data['profileImageUrl'],
      preferences: data['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'isPremium': isPremium,
      'createdAt': Timestamp.fromDate(createdAt),
      'premiumExpiresAt': premiumExpiresAt != null
          ? Timestamp.fromDate(premiumExpiresAt!)
          : null,
      'profileImageUrl': profileImageUrl,
      'preferences': preferences,
      'lastUpdated': Timestamp.now(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? premiumExpiresAt,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper getters
  String get firstName => name.split(' ').first;
  bool get isPremiumActive =>
      isPremium &&
      (premiumExpiresAt == null || premiumExpiresAt!.isAfter(DateTime.now()));
}
