import 'package:cloud_firestore/cloud_firestore.dart';
import 'store.dart';

class BusinessUser {
  final String id;
  final String userId;
  final String storeId;
  final String phoneNumber;
  final bool isApproved;
  Store? store; // Optional store object for when we need the full store data

  BusinessUser({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.phoneNumber,
    required this.isApproved,
    this.store,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeId': storeId,
      'phoneNumber': phoneNumber,
      'isApproved': isApproved,
    };
  }

  factory BusinessUser.fromMap(String id, Map<String, dynamic> map) {
    return BusinessUser(
      id: id,
      userId: map['userId'],
      storeId: map['storeId'],
      phoneNumber: map['phoneNumber'] ?? '',
      isApproved: map['isApproved'] ?? false,
    );
  }

  BusinessUser copyWith({
    String? userId,
    String? storeId,
    String? phoneNumber,
    bool? isApproved,
    Store? store,
  }) {
    return BusinessUser(
      id: id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isApproved: isApproved ?? this.isApproved,
      store: store ?? this.store,
    );
  }
}
