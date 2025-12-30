import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateTenantPage extends StatefulWidget {
  const CreateTenantPage({super.key});

  @override
  State<CreateTenantPage> createState() => _CreateTenantPageState();
}

class _CreateTenantPageState extends State<CreateTenantPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create tenant / app'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: const CreateTenantForm(),
    );
  }
}

class CreateTenantForm extends StatefulWidget {
  final EdgeInsets padding;

  const CreateTenantForm({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CreateTenantForm> createState() => _CreateTenantFormState();
}

class _CreateTenantFormState extends State<CreateTenantForm> {
  final _tenantId = TextEditingController();
  final _tenantName = TextEditingController();
  final _signLangId = TextEditingController();
  final _uiLocales = TextEditingController(text: 'en');
  final _logoUrl = TextEditingController();
  final _primary = TextEditingController(text: '#232F34');
  final _secondary = TextEditingController(text: '#F9AA33');

  final _appId = TextEditingController();
  final _appName = TextEditingController();
  bool _createApp = true;
  bool _publicTenant = true;
  bool _loading = false;

  List<String> _parseLocales(String s) {
    return s
        .split(',')
        .map((x) => x.trim().toLowerCase())
        .where((x) => x.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic> _brand() {
    final m = <String, dynamic>{
      'primary': _primary.text.trim(),
      'secondary': _secondary.text.trim(),
    };
    final logo = _logoUrl.text.trim();
    if (logo.isNotEmpty) m['logoUrl'] = logo;
    return m;
  }

  Future<void> _submit() async {
    final tenantId = _tenantId.text.trim();
    final signLangId = _signLangId.text.trim();
    if (tenantId.isEmpty || signLangId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('tenantId and signLangId are required')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final locales = _parseLocales(_uiLocales.text);

      // tenants/{tenantId}
      await db.collection('tenants').doc(tenantId).set(
        {
          'status': 'active',
          'visibility': _publicTenant ? 'public' : 'private',
          'displayName': _tenantName.text.trim(),
          'signLangId': signLangId,
          'uiLocales': locales,
          'brand': _brand(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (_createApp) {
        final appId = _appId.text.trim();
        if (appId.isEmpty) {
          throw Exception('appId is required when "Create app" is enabled.');
        }
        await db.collection('apps').doc(appId).set(
          {
            'status': 'active',
            'tenantId': tenantId,
            'signLangId': signLangId,
            'displayName': (_appName.text.trim().isNotEmpty) ? _appName.text.trim() : _tenantName.text.trim(),
            'uiLocales': locales,
            'brand': _brand(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Created / updated successfully')));
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
    _tenantName.dispose();
    _signLangId.dispose();
    _uiLocales.dispose();
    _logoUrl.dispose();
    _primary.dispose();
    _secondary.dispose();
    _appId.dispose();
    _appName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: widget.padding,
      children: [
          Text('Tenant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(controller: _tenantId, decoration: const InputDecoration(labelText: 'tenantId (e.g. l2l-bdsl)')),
          TextField(controller: _signLangId, decoration: const InputDecoration(labelText: 'signLangId (e.g. bdsl)')),
          TextField(controller: _tenantName, decoration: const InputDecoration(labelText: 'displayName')),
          TextField(controller: _uiLocales, decoration: const InputDecoration(labelText: 'uiLocales CSV (e.g. en,bn)')),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public tenant (guests can read content)'),
            value: _publicTenant,
            onChanged: (v) => setState(() => _publicTenant = v),
          ),
          const SizedBox(height: 16),
          Text('Brand', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(controller: _logoUrl, decoration: const InputDecoration(labelText: 'logoUrl (optional)')),
          TextField(controller: _primary, decoration: const InputDecoration(labelText: 'primary (hex #RRGGBB)')),
          TextField(controller: _secondary, decoration: const InputDecoration(labelText: 'secondary (hex #RRGGBB)')),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Also create/update apps/{appId}'),
            value: _createApp,
            onChanged: (v) => setState(() => _createApp = v),
          ),
          if (_createApp) ...[
            TextField(controller: _appId, decoration: const InputDecoration(labelText: 'appId (e.g. love2learnsign)')),
            TextField(controller: _appName, decoration: const InputDecoration(labelText: 'app displayName (optional)')),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
      ],
    );
  }
}


