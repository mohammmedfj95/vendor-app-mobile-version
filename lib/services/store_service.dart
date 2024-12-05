import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/store.dart';
import '../models/business_user.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new store (only for store owners)
  Future<Store> createStore(Store store, String phoneNumber) async {
    print('Creating store with name: ${store.storeName}');
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      // Check for uniqueness
      if (await isEmailInUse(user.email!)) {
        throw Exception('Email is already in use');
      }
      if (await isPhoneNumberInUse(phoneNumber)) {
        throw Exception('Phone number is already in use');
      }
      if (await isStoreNameInUse(store.storeName)) {
        throw Exception('Store name is already in use');
      }

      // Create the store
      final storeRef = await _firestore.collection('stores').add({
        ...store.toMap(),
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Created store with ID: ${storeRef.id}');

      // Create the store owner
      final storeOwnerRef = await _firestore.collection('store_owners').add({
        'userId': user.uid,
        'storeId': storeRef.id,
        'phoneNumber': phoneNumber,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'owner',
      });

      print('Created store owner record with ID: ${storeOwnerRef.id}');

      return store.copyWith(id: storeRef.id);
    } catch (e) {
      print('Error creating store: $e');
      throw Exception('Failed to create store: $e');
    }
  }

  // Get store by ID
  Future<Store?> getStore(String storeId) async {
    final doc = await _firestore.collection('stores').doc(storeId).get();
    if (!doc.exists) return null;
    return Store.fromMap(doc.id, doc.data()!);
  }

  // Get current user's store (whether owner or business user)
  Future<Store?> getCurrentUserStore() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check if user is a store owner
    final ownerSnapshot = await _firestore
        .collection('store_owners')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (ownerSnapshot.docs.isNotEmpty) {
      final storeId = ownerSnapshot.docs.first.get('storeId');
      return await getStore(storeId);
    }

    // Check if user is a business user
    final businessUserSnapshot = await _firestore
        .collection('business_users')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (businessUserSnapshot.docs.isNotEmpty) {
      final storeId = businessUserSnapshot.docs.first.get('storeId');
      return await getStore(storeId);
    }

    return null;
  }

  // Get current user's role (owner or business user)
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final ownerDoc = await _firestore
        .collection('store_owners')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (ownerDoc.docs.isNotEmpty) {
      return 'owner';
    }

    final businessUserDoc = await _firestore
        .collection('business_users')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (businessUserDoc.docs.isNotEmpty) {
      return 'business_user';
    }

    return 'none';
  }

  // Update store
  Future<void> updateStore(Store store) async {
    await _firestore.collection('stores').doc(store.id).update(store.toMap());
  }

  // Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    final storeOwnerQuery = await _firestore
        .collection('store_owners')
        .where('email', isEqualTo: email)
        .get();

    final businessUserQuery = await _firestore
        .collection('business_users')
        .where('email', isEqualTo: email)
        .get();

    return storeOwnerQuery.docs.isNotEmpty || businessUserQuery.docs.isNotEmpty;
  }

  // Check if phone number is already in use
  Future<bool> isPhoneNumberInUse(String phoneNumber) async {
    final storeOwnerQuery = await _firestore
        .collection('store_owners')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();

    final businessUserQuery = await _firestore
        .collection('business_users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();

    return storeOwnerQuery.docs.isNotEmpty || businessUserQuery.docs.isNotEmpty;
  }

  // Check if store name is already in use
  Future<bool> isStoreNameInUse(String storeName) async {
    final storeQuery = await _firestore
        .collection('stores')
        .where('storeName', isEqualTo: storeName)
        .get();

    return storeQuery.docs.isNotEmpty;
  }

  // Check if store owner exists
  Future<bool> checkStoreOwnerExists(String ownerEmail) async {
    print('Checking store owner with email: $ownerEmail');

    try {
      // Check directly in store_owners collection by email
      final storeOwnerQuery = await _firestore
          .collection('store_owners')
          .where('email', isEqualTo: ownerEmail)
          .get();

      print('Found ${storeOwnerQuery.docs.length} store owners with email $ownerEmail');
      return storeOwnerQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking store owner: $e');
      return false;
    }
  }

  // Register as a business user for a store
  Future<void> registerAsBusinessUser(
      String ownerEmail, String phoneNumber) async {
    print('Registering business user for owner email: $ownerEmail');

    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      // Check for uniqueness
      if (await isEmailInUse(user.email!)) {
        throw Exception('Email is already in use');
      }
      if (await isPhoneNumberInUse(phoneNumber)) {
        throw Exception('Phone number is already in use');
      }

      // Find the store owner by email directly in store_owners collection
      final storeOwnerQuery = await _firestore
          .collection('store_owners')
          .where('email', isEqualTo: ownerEmail)
          .get();

      print('Found ${storeOwnerQuery.docs.length} store owners with email $ownerEmail');

      if (storeOwnerQuery.docs.isEmpty) {
        throw Exception('Store owner not found');
      }

      final storeOwnerDoc = storeOwnerQuery.docs.first;
      final storeId = storeOwnerDoc.get('storeId');
      print('Found store with ID: $storeId');

      // Register as a business user
      await _firestore.collection('business_users').add({
        'userId': user.uid,
        'storeId': storeId,
        'phoneNumber': phoneNumber,
        'isApproved': false,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Successfully registered business user');
    } catch (e) {
      print('Error registering business user: $e');
      throw Exception('Failed to register as business user: $e');
    }
  }

  // Get all business users for a store
  Future<List<BusinessUser>> getStoreBusinessUsers(String storeId) async {
    final snapshot = await _firestore
        .collection('business_users')
        .where('storeId', isEqualTo: storeId)
        .get();

    return snapshot.docs
        .map((doc) => BusinessUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Approve/reject business user (only for store owners)
  Future<void> setBusinessUserApproval(
      String businessUserId, bool approved) async {
    await _firestore
        .collection('business_users')
        .doc(businessUserId)
        .update({'isApproved': approved});
  }
}
