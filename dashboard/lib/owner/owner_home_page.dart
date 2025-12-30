import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'assign_access_page.dart';
import 'create_tenant_page.dart';
import 'monetization_config_page.dart';
import 'monetization_metrics_page.dart';

enum _OwnerSection {
  createTenant,
  manageTenants,
  manageAccess,
  monetizationConfig,
  monetizationMetrics,
}

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  _OwnerSection _section = _OwnerSection.createTenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;

        final menu = _OwnerMenu(
          selected: _section,
          onSelect: (s) => setState(() => _section = s),
        );

        final content = _OwnerContent(section: _section);

        if (!wide) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Owner'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: DropdownButtonFormField<_OwnerSection>(
                    value: _section,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: _OwnerMenu.items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.section,
                            child: Text(i.title),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _section = v ?? _section),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(width: 300, child: menu),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerMenuItem {
  final _OwnerSection section;
  final String title;
  final String subtitle;
  final IconData icon;

  const _OwnerMenuItem({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OwnerMenu extends StatelessWidget {
  final _OwnerSection selected;
  final ValueChanged<_OwnerSection> onSelect;

  const _OwnerMenu({
    required this.selected,
    required this.onSelect,
  });

  static const items = <_OwnerMenuItem>[
    _OwnerMenuItem(
      section: _OwnerSection.createTenant,
      title: 'Create tenant / app',
      subtitle: 'Create tenants/* and (optionally) apps/*.',
      icon: Icons.add_business,
    ),
    _OwnerMenuItem(
      section: _OwnerSection.manageTenants,
      title: 'Manage tenants',
      subtitle: 'Edit displayName, uiLocales, visibility, brand.',
      icon: Icons.domain_outlined,
    ),
    _OwnerMenuItem(
      section: _OwnerSection.manageAccess,
      title: 'Manage access',
      subtitle: 'Search users and edit tenant roles.',
      icon: Icons.admin_panel_settings_outlined,
    ),
    _OwnerMenuItem(
      section: _OwnerSection.monetizationConfig,
      title: 'Monetization config',
      subtitle: 'Per-tenant AdMob + IAP SKUs.',
      icon: Icons.payments_outlined,
    ),
    _OwnerMenuItem(
      section: _OwnerSection.monetizationMetrics,
      title: 'Monetization metrics',
      subtitle: 'Active subscribers per tenant.',
      icon: Icons.insights_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
        children: [
          Text('Owner',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Platform-level tools.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 12),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _OwnerMenuTile(
                item: i,
                selected: i.section == selected,
                onTap: () => onSelect(i.section),
              ),
            ),
        ],
      ),
    );
  }
}

class _OwnerMenuTile extends StatelessWidget {
  final _OwnerMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  const _OwnerMenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.secondary.withValues(alpha: 0.18) : scheme.surface;
    final fg = selected ? scheme.secondary : scheme.onSurface.withValues(alpha: 0.85);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: fg,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerContent extends StatelessWidget {
  final _OwnerSection section;

  const _OwnerContent({required this.section});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    switch (section) {
      case _OwnerSection.createTenant:
        inner = const CreateTenantForm(padding: EdgeInsets.zero);
        break;
      case _OwnerSection.manageTenants:
        inner = const _ManageTenantsView();
        break;
      case _OwnerSection.manageAccess:
        inner = const AssignAccessForm(padding: EdgeInsets.zero);
        break;
      case _OwnerSection.monetizationConfig:
        inner = const MonetizationConfigPage(embedded: true);
        break;
      case _OwnerSection.monetizationMetrics:
        inner = const MonetizationMetricsPage(embedded: true);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: inner,
          ),
        ),
      ),
    );
  }
}

class _ManageTenantsView extends StatefulWidget {
  const _ManageTenantsView();

  @override
  State<_ManageTenantsView> createState() => _ManageTenantsViewState();
}

class _ManageTenantsViewState extends State<_ManageTenantsView> {
  final _search = TextEditingController();

  String? _selectedTenantId;
  bool _saving = false;
  String? _error;

  final _displayName = TextEditingController();
  final _signLangId = TextEditingController();
  final _uiLocales = TextEditingController();
  String _visibility = 'public';
  final _logoUrl = TextEditingController();
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _displayName.dispose();
    _signLangId.dispose();
    _uiLocales.dispose();
    _logoUrl.dispose();
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  void _loadFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final brand = (data['brand'] is Map) ? Map<String, dynamic>.from(data['brand']) : <String, dynamic>{};

    _displayName.text = (data['displayName'] ?? '').toString();
    _signLangId.text = (data['signLangId'] ?? '').toString();
    final locales = (data['uiLocales'] is List) ? (data['uiLocales'] as List).map((e) => e.toString()).toList() : <String>[];
    _uiLocales.text = locales.join(',');
    _visibility = (data['visibility'] ?? 'public').toString();
    _logoUrl.text = (brand['logoUrl'] ?? '').toString();
    _primary.text = (brand['primary'] ?? '').toString();
    _secondary.text = (brand['secondary'] ?? '').toString();
  }

  Future<void> _save() async {
    final tenantId = (_selectedTenantId ?? '').trim();
    if (tenantId.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final locales = _uiLocales.text
          .split(',')
          .map((x) => x.trim().toLowerCase())
          .where((x) => x.isNotEmpty)
          .toSet()
          .toList();

      final payload = <String, dynamic>{
        'displayName': _displayName.text.trim(),
        'signLangId': _signLangId.text.trim(),
        'uiLocales': locales,
        'visibility': _visibility,
        'brand': {
          'logoUrl': _logoUrl.text.trim(),
          'primary': _primary.text.trim(),
          'secondary': _secondary.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('tenants').doc(tenantId).set(payload, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text('Manage tenants',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            labelText: 'Search (tenantId or displayName)',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final listPane = Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('tenants').snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load tenants: ${snap.error}'),
                    );
                  }
                  final q = _search.text.trim().toLowerCase();
                  final docs = (snap.data?.docs ?? const [])
                      .where((d) {
                        if (q.isEmpty) return true;
                        final data = d.data();
                        final name = (data['displayName'] ?? '').toString().toLowerCase();
                        final id = d.id.toLowerCase();
                        return id.contains(q) || name.contains(q);
                      })
                      .toList()
                    ..sort((a, b) {
                      final an = (a.data()['displayName'] ?? '').toString();
                      final bn = (b.data()['displayName'] ?? '').toString();
                      return ('$an (${a.id})').compareTo('$bn (${b.id})');
                    });

                  return ListView(
                    children: [
                      for (final d in docs)
                        ListTile(
                          selected: d.id == _selectedTenantId,
                          title: Text(((d.data()['displayName'] ?? '') as Object)
                                      .toString()
                                      .trim()
                                      .isEmpty
                                  ? d.id
                                  : '${d.data()['displayName']}'),
                          subtitle: Text(d.id),
                          trailing: d.id == _selectedTenantId
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedTenantId = d.id;
                              _loadFromDoc(d);
                            });
                          },
                        ),
                    ],
                  );
                },
              ),
            );

            final editorPane = Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: (_selectedTenantId == null)
                    ? const Text('Select a tenant to edit.')
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Tenant: $_selectedTenantId',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: scheme.onErrorContainer),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                                controller: _displayName,
                                decoration:
                                    const InputDecoration(labelText: 'displayName')),
                            TextField(
                                controller: _signLangId,
                                decoration:
                                    const InputDecoration(labelText: 'signLangId')),
                            TextField(
                                controller: _uiLocales,
                                decoration: const InputDecoration(
                                    labelText: 'uiLocales CSV (e.g. en,bn)')),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _visibility,
                              decoration:
                                  const InputDecoration(labelText: 'visibility'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'public', child: Text('public')),
                                DropdownMenuItem(
                                    value: 'private', child: Text('private')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _visibility = v ?? 'public'),
                            ),
                            const SizedBox(height: 12),
                            Text('Brand',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            TextField(
                                controller: _logoUrl,
                                decoration: const InputDecoration(labelText: 'logoUrl')),
                            TextField(
                                controller: _primary,
                                decoration: const InputDecoration(
                                    labelText: 'primary (hex #RRGGBB)')),
                            TextField(
                                controller: _secondary,
                                decoration: const InputDecoration(
                                    labelText: 'secondary (hex #RRGGBB)')),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.save),
                              label: Text(_saving ? 'Saving...' : 'Save'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: tenantId/appId renames are not supported here.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.70)),
                            ),
                          ],
                        ),
                      ),
              ),
            );

            if (!wide) {
              return Column(
                children: [
                  SizedBox(height: 320, child: listPane),
                  const SizedBox(height: 12),
                  editorPane,
                ],
              );
            }

            return SizedBox(
              height: 520,
              child: Row(
                children: [
                  Flexible(flex: 3, child: listPane),
                  const SizedBox(width: 12),
                  Flexible(flex: 5, child: editorPane),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}


