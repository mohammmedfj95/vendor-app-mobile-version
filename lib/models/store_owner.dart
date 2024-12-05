import 'package:cloud_firestore/cloud_firestore.dart';
import 'store.dart';

class StoreOwner {
  final String id;
  final String userId;
  final String storeId;
  final String phoneNumber;
  Store? store; // Optional store object for when we need the full store data

  StoreOwner({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.phoneNumber,
    this.store,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeId': storeId,
      'phoneNumber': phoneNumber,
    };
  }

  factory StoreOwner.fromMap(String id, Map<String, dynamic> map) {
    return StoreOwner(
      id: id,
      userId: map['userId'],
      storeId: map['storeId'],
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  StoreOwner copyWith({
    String? userId,
    String? storeId,
    String? phoneNumber,
    Store? store,
  }) {
    return StoreOwner(
      id: id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      store: store ?? this.store,
    );
  }
}
