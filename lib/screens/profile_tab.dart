import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().updateProfile(
            uid: uid,
            displayName: _name.text.trim(),
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not signed in.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snapshot.data!;
        if (!doc.exists) {
          return const Center(child: Text('Profile not found.'));
        }
        final user = AppUser.fromFirestore(doc);
        if (!_editing) {
          _name.text = user.displayName;
          _phone.text = user.phone ?? '';
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name'),
              readOnly: !_editing,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (for WhatsApp)',
                hintText: 'Include country code, e.g. 9627…',
              ),
              readOnly: !_editing,
            ),
            const SizedBox(height: 24),
            if (_editing)
              FilledButton(
                onPressed: _saving ? null : () => _save(uid),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              )
            else
              OutlinedButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Edit profile'),
              ),
            const SizedBox(height: 32),
            Text(
              'Add your phone number so buyers can reach you on WhatsApp from a listing.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AuthService>().signOut();
                }
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }
}
