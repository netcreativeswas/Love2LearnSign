import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignAccessPage extends StatefulWidget {
  const AssignAccessPage({super.key});

  @override
  State<AssignAccessPage> createState() => _AssignAccessPageState();
}

class _AssignAccessPageState extends State<AssignAccessPage> {
  final _tenantId = TextEditingController();
  final _uid = TextEditingController();
  String _role = 'admin';
  bool _loading = false;

  Future<void> _submit() async {
    final tenantId = _tenantId.text.trim();
    final uid = _uid.text.trim();
    if (tenantId.isEmpty || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('tenantId and uid are required')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;

      // tenants/{tenantId}/members/{uid}
      await db.collection('tenants').doc(tenantId).collection('members').doc(uid).set(
        {
          'uid': uid,
          'role': _role,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // userTenants/{uid} merge index
      await db.collection('userTenants').doc(uid).set(
        {
          'tenants': {
            tenantId: {'role': _role, 'status': 'active'}
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access assigned')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tenantId.dispose();
    _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign tenant access'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _tenantId, decoration: const InputDecoration(labelText: 'tenantId')),
          TextField(controller: _uid, decoration: const InputDecoration(labelText: 'user uid')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'role'),
            items: const [
              DropdownMenuItem(value: 'owner', child: Text('owner')),
              DropdownMenuItem(value: 'admin', child: Text('admin')),
              DropdownMenuItem(value: 'editor', child: Text('editor')),
              DropdownMenuItem(value: 'analyst', child: Text('analyst')),
              DropdownMenuItem(value: 'viewer', child: Text('viewer')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'admin'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: this requires platform admin privileges (platform/platform/members/{uid}).',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}


