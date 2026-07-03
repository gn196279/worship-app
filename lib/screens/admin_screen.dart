import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../services/user_role_service.dart';
import '../theme/app_colors.dart';
import '../utils/access_control.dart';
import '../widgets/app_snackbar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final UserRoleService _roleService = UserRoleService();
  String? _updatingUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAccess());
  }

  void _guardAccess() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.firebaseUser != null && auth.appUser == null) {
      Future.delayed(const Duration(milliseconds: 300), _guardAccess);
      return;
    }
    final access = AccessControl.from(
      isGuestMode: auth.firebaseUser == null,
      firestoreRole: auth.appUser?.role,
    );
    if (!access.canManageRoles) {
      Navigator.of(context).pop();
      AppSnackBar.warning(context, 'Admin access only.');
    }
  }

  Future<void> _changeRole({
    required String targetUid,
    required String adminUid,
    required String newRole,
    required String displayName,
  }) async {
    if (_updatingUid != null) return;

    setState(() => _updatingUid = targetUid);
    try {
      await _roleService.updateRole(
        adminUid: adminUid,
        targetUid: targetUid,
        role: newRole,
      );
      if (!mounted) return;
      AppSnackBar.success(
        context,
        '${displayName.trim().isEmpty ? 'User' : displayName} is now ${UserRole.label(newRole)}.',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not update role. Please try again.');
    } finally {
      if (mounted) setState(() => _updatingUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final adminUid = auth.firebaseUser?.uid;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: AppColors.appBarBackground(isDark),
      ),
      body: adminUid == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role management',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Change a user\'s role with the dropdown. You cannot '
                          'change your own role.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Singer — browse, favorites, share, download PDF\n'
                          '• Musician — singer + upload, edit songs, chord charts\n'
                          '• Admin — musician + manage user roles',
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Registered users',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Could not load users: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No users found yet.'),
                      );
                    }
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final uid = doc.id;
                        final email = data['email'] as String? ?? uid;
                        final name = data['displayName'] as String?;
                        final currentRole =
                            UserRole.normalize(data['role'] as String?);
                        final isSelf = uid == adminUid;
                        final isUpdating = _updatingUid == uid;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    (name ?? email).substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name ?? email,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (name != null)
                                        Text(
                                          email,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.hintColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (isSelf)
                                        Text(
                                          'You — role locked',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isUpdating)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else if (isSelf)
                                  Chip(label: Text(UserRole.label(currentRole)))
                                else
                                  DropdownButton<String>(
                                    value: currentRole,
                                    underline: const SizedBox.shrink(),
                                    items: UserRole.all
                                        .map(
                                          (role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(UserRole.label(role)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (newRole) {
                                      if (newRole == null ||
                                          newRole == currentRole) {
                                        return;
                                      }
                                      unawaited(
                                        _changeRole(
                                          targetUid: uid,
                                          adminUid: adminUid,
                                          newRole: newRole,
                                          displayName: name ?? email,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
