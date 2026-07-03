import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';

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
    final ref = _users.doc(uid);

    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (snap.exists && snap.data() != null) {
        return AppUser.fromMap(snap.data()!, snap.id);
      }

      final user = AppUser(
        uid: uid,
        email: email,
        displayName: displayName,
        role: UserRole.singer,
        createdAt: DateTime.now(),
      );
      transaction.set(ref, user.toMap());
      return user;
    });
  }

  /// Admin-only: assign a role to another user (never self).
  Future<void> updateRole({
    required String adminUid,
    required String targetUid,
    required String role,
  }) async {
    if (adminUid == targetUid) {
      throw StateError('You cannot change your own role.');
    }
    if (!UserRole.all.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Invalid role');
    }
    await _users.doc(targetUid).update({'role': role});
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap(snapshot.data()!, snapshot.id);
    });
  }
}

