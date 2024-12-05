import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  String? id;  
  final String storeName;
  final String address;
  final String businessType;
  final DateTime accountCreationDate;
  final String subscriptionPlan;
  final int numberOfStoreUsers;
  final int? discountThreshold;
  final double? discount;
  final bool subscriptionActive;

  Store({
    this.id,  
    required this.storeName,
    required this.address,
    required this.businessType,
    required this.accountCreationDate,
    required this.subscriptionPlan,
    required this.numberOfStoreUsers,
    this.discountThreshold,
    this.discount,
    required this.subscriptionActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'address': address,
      'businessType': businessType,
      'accountCreationDate': Timestamp.fromDate(accountCreationDate),
      'subscriptionPlan': subscriptionPlan,
      'numberOfStoreUsers': numberOfStoreUsers,
      'discountThreshold': discountThreshold,
      'discount': discount,
      'subscriptionActive': subscriptionActive,
    };
  }

  factory Store.fromMap(String documentId, Map<String, dynamic> map) {
    return Store(
      id: documentId,
      storeName: map['storeName'] ?? 'Store Name',
      address: map['address'] ?? '',
      businessType: map['businessType'] ?? '',
      accountCreationDate: (map['accountCreationDate'] as Timestamp).toDate(),
      subscriptionPlan: map['subscriptionPlan'] ?? 'Monthly',
      numberOfStoreUsers: map['numberOfStoreUsers'] ?? 0,
      discountThreshold: map['discountThreshold'],
      discount: map['discount']?.toDouble(),
      subscriptionActive: map['subscriptionActive'] ?? false,
    );
  }

  Store copyWith({
    String? id,
    String? storeName,
    String? address,
    String? businessType,
    DateTime? accountCreationDate,
    String? subscriptionPlan,
    int? numberOfStoreUsers,
    int? discountThreshold,
    double? discount,
    bool? subscriptionActive,
  }) {
    return Store(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      businessType: businessType ?? this.businessType,
      accountCreationDate: accountCreationDate ?? this.accountCreationDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      numberOfStoreUsers: numberOfStoreUsers ?? this.numberOfStoreUsers,
      discountThreshold: discountThreshold ?? this.discountThreshold,
      discount: discount ?? this.discount,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
    );
  }
}
