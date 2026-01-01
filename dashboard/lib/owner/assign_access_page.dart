import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AssignAccessPage extends StatelessWidget {
  const AssignAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage access'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: const AssignAccessForm(),
    );
  }
}

class AssignAccessForm extends StatefulWidget {
  final EdgeInsets padding;

  const AssignAccessForm({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<AssignAccessForm> createState() => _AssignAccessFormState();
}

class _AssignAccessFormState extends State<AssignAccessForm> {
  final _search = TextEditingController();
  final _uid = TextEditingController();

  String? _selectedTenantId;
  String _role = 'admin';
  String _status = 'active';

  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _userResults = const [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedUser;

  @override
  void dispose() {
    _search.dispose();
    _uid.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() {
        _userResults = const [];
        _selectedUser = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _userResults = const [];
      _selectedUser = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      QuerySnapshot<Map<String, dynamic>> snap;
      if (q.contains('@')) {
        snap = await db.collection('users').where('email', isEqualTo: q).limit(10).get();
      } else {
        // Prefix search on displayName (best-effort). If this fails due to missing index/rules,
        // admin can still paste uid directly.
        final end = '$q\uf8ff';
        snap = await db
            .collection('users')
            .orderBy('displayName')
            .startAt([q])
            .endAt([end])
            .limit(10)
            .get();
      }

      setState(() {
        _userResults = snap.docs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Search failed: $e';
      });
    }
  }

  String _uidFromUserDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    final uid = (data['uid'] ?? '').toString().trim();
    return uid.isNotEmpty ? uid : d.id;
  }

  Future<void> _saveAccess({required String tenantId, required String uid}) async {
    if (tenantId.trim().isEmpty || uid.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('setTenantMemberRole');
      await callable.call({
        'tenantId': tenantId,
        'targetUid': uid,
        'role': _role,
        'status': _status,
      });

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Save failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedUid = _selectedUser != null ? _uidFromUserDoc(_selectedUser!) : _uid.text.trim();
    final selectedTenant = (_selectedTenantId ?? '').trim();

    return ListView(
      padding: widget.padding,
      children: [
        Text(
          'Manage Access',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Assign or edit tenant roles. Writes both `tenants/{tenantId}/members/{uid}` and `userTenants/{uid}`.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('tenants').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? const [];
            final tenants = docs
                .map((d) => {
                      'id': d.id,
                      'name': (d.data()['displayName'] ?? '').toString().trim(),
                    })
                .toList()
              ..sort((a, b) => ('${a['name']} (${a['id']})').compareTo('${b['name']} (${b['id']})'));

            return DropdownButtonFormField<String>(
              value: _selectedTenantId,
              decoration: const InputDecoration(labelText: 'Tenant'),
              items: tenants
                  .map(
                    (t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text(
                        (t['name'] as String).isEmpty
                            ? (t['id'] as String)
                            : '${t['name']} (${t['id']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loading ? null : (v) => setState(() => _selectedTenantId = v),
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: 'Search user (email exact or displayName prefix)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: _loading ? null : () => setState(() => _search.text = ''),
                    icon: const Icon(Icons.clear),
                  ),
          ),
          onSubmitted: (_) => _runSearch(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _loading ? null : _runSearch,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: const Text('Search'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _uid,
                decoration: const InputDecoration(labelText: 'Or paste uid'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_userResults.isNotEmpty) ...[
          Text('Results:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ..._userResults.map((d) {
            final data = d.data();
            final uid = _uidFromUserDoc(d);
            final email = (data['email'] ?? '').toString();
            final name = (data['displayName'] ?? '').toString();
            final selected = _selectedUser?.id == d.id;
            return ListTile(
              dense: true,
              leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              title: Text(name.isEmpty ? uid : name),
              subtitle: Text([if (email.isNotEmpty) email, 'uid=$uid'].join(' • ')),
              onTap: () => setState(() {
                _selectedUser = d;
                _uid.text = uid;
              }),
            );
          }),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          value: _role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: const [
            DropdownMenuItem(value: 'owner', child: Text('owner')),
            DropdownMenuItem(value: 'admin', child: Text('admin')),
          ],
          onChanged: _loading ? null : (v) => setState(() => _role = v ?? 'admin'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('active')),
            DropdownMenuItem(value: 'inactive', child: Text('inactive')),
          ],
          onChanged: _loading ? null : (v) => setState(() => _status = v ?? 'active'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: (_loading || selectedTenant.isEmpty || selectedUid.isEmpty)
              ? null
              : () => _saveAccess(tenantId: selectedTenant, uid: selectedUid),
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: const Text('Save'),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: if search fails (rules/index), paste uid directly.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (selectedTenant.isNotEmpty) ...[
          Text('Members of $selectedTenant', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('tenants').doc(selectedTenant).collection('members').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text('Failed to load members: ${snap.error}');
              }
              final allDocs = snap.data?.docs ?? const [];
              final docs = allDocs.where((m) {
                final data = m.data();
                final role = (data['role'] ?? '').toString().toLowerCase().trim();
                return role == 'owner' || role == 'admin';
              }).toList();
              if (docs.isEmpty) return const Text('No members');
              return Column(
                children: docs.map((m) {
                  final data = m.data();
                  final uid = (data['uid'] ?? m.id).toString();
                  final role = (data['role'] ?? '').toString();
                  final status = (data['status'] ?? '').toString();
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline),
                    title: Text(uid),
                    subtitle: Text([if (role.isNotEmpty) 'role=$role', if (status.isNotEmpty) 'status=$status'].join(' • ')),
                    trailing: TextButton(
                      onPressed: () => setState(() {
                        _selectedUser = null;
                        _uid.text = uid;
                        if (role.isNotEmpty) _role = role;
                        if (status.isNotEmpty) _status = status;
                      }),
                      child: const Text('Edit'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}


