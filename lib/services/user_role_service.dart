import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class UserRoleService {
  UserRoleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<AppUser> getOrCreateUser({
    required String uid,
    required String? email,
    required String? displayName,
  }) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }

    final user = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: 'user',
      createdAt: DateTime.now(),
    );

    try {
      await _users.doc(uid).set(user.toMap());
    } catch (e) {
      debugPrint('Failed to create user doc: $e');
    }

    return user;
  }

  Future<void> updateRole({
    required String uid,
    required String role,
  }) async {
    await _users.doc(uid).update({'role': role});
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap(snapshot.data()!, snapshot.id);
    });
  }
}

