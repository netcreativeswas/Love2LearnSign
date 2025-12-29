import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'package:provider/provider.dart';

import '../tenancy/tenant_storage_paths.dart';
import '../tenancy/tenant_db.dart';
import 'words_media_service.dart';
import 'words_repository.dart';

class WordsEditorPage extends StatelessWidget {
  final String wordId;
  final String? userRoleOverride;
  final String tenantId;
  final String signLangId;

  const WordsEditorPage({
    super.key,
    required this.wordId,
    this.userRoleOverride,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit word')),
      body: WordsEditorView(
        wordId: wordId,
        userRoleOverride: userRoleOverride,
        tenantId: tenantId,
        signLangId: signLangId,
        embedded: false,
      ),
    );
  }
}

class WordsEditorView extends StatefulWidget {
  final String wordId;
  final String? userRoleOverride;
  final String tenantId;
  final String signLangId;
  final bool embedded;
  final VoidCallback? onDeleted;
  final VoidCallback? onSaved;

  const WordsEditorView({
    super.key,
    required this.wordId,
    this.userRoleOverride,
    this.tenantId = TenantDb.defaultTenantId,
    this.signLangId = TenantDb.defaultSignLangId,
    required this.embedded,
    this.onDeleted,
    this.onSaved,
  });

  @override
  State<WordsEditorView> createState() => _WordsEditorViewState();
}

class _WordsEditorViewState extends State<WordsEditorView> {
  late final WordsRepository _repo;
  final WordsMediaService _media = WordsMediaService();

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo = WordsRepository(tenantId: widget.tenantId, signLangId: widget.signLangId);
  }

  bool _isAdmin(BuildContext context) {
    final override = widget.userRoleOverride?.toLowerCase().trim();
    if (override == 'admin') return true;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      return auth.isAdmin;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveField(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
      if (!mounted) return;
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteWord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete word'),
        content: const Text('This will delete the word and all associated media. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await _repo.deleteDictionaryEntryCascade(wordId: widget.wordId);
      if (!mounted) return;
      widget.onDeleted?.call();
      if (!widget.embedded) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      setState(() => _busy = false);
    }
  }

  Future<void> _replaceMainFlashcard() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    await _saveField(() async {
      final url = await _media.uploadPlatformFile(
        file,
        storageDir: TenantStoragePaths.flashcardsDir(conceptId: widget.wordId),
      );
      await _repo.updateFields(widget.wordId, {'imageFlashcard': url});
    });
  }

  Future<void> _replaceVariantMedia({
    required int index,
    required String fieldKey,
    required String storageDir,
    required FileType fileType,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    await _saveField(() async {
      final url = await _media.uploadPlatformFile(file, storageDir: storageDir);
      await _repo.updateVariantAtIndex(
        wordId: widget.wordId,
        index: index,
        mutateVariant: (v) {
          v[fieldKey] = url;
          return v;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _repo.streamWord(widget.wordId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Failed to load: ${snap.error}'));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Word not found'));
        }

        final data = snap.data!.data() ?? <String, dynamic>{};
        final english = (data['english'] ?? '').toString();
        final bengali = (data['bengali'] ?? '').toString();
        final englishNote = (data['englishNote'] ?? '').toString();
        final bengaliNote = (data['bengaliNote'] ?? '').toString();
        final categoryMain = (data['category_main'] ?? '').toString();
        final categorySub = (data['category_sub'] ?? '').toString();
        final imageFlashcard = (data['imageFlashcard'] ?? '').toString();

        final englishSyn = (data['englishWordSynonyms'] is List)
            ? List<String>.from(data['englishWordSynonyms'])
            : const <String>[];
        final bengaliSyn = (data['bengaliWordSynonyms'] is List)
            ? List<String>.from(data['bengaliWordSynonyms'])
            : const <String>[];
        final englishAnt = (data['englishWordAntonyms'] is List)
            ? List<String>.from(data['englishWordAntonyms'])
            : const <String>[];
        final bengaliAnt = (data['bengaliWordAntonyms'] is List)
            ? List<String>.from(data['bengaliWordAntonyms'])
            : const <String>[];

        final categoriesRaw = (data['categories'] is List) ? (data['categories'] as List) : const <dynamic>[];
        final categoriesJson = const JsonEncoder.withIndent('  ').convert(categoriesRaw);

        final variantsRaw = (data['variants'] is List) ? (data['variants'] as List) : const <dynamic>[];
        final variants = variantsRaw
            .map((e) => (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();

        return AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Document: ${widget.wordId}',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isAdmin(context))
                    TextButton.icon(
                      onPressed: _deleteWord,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Main fields',
                child: Column(
                  children: [
                    _EditableTextField(
                      label: 'English',
                      initialValue: english,
                      onSave: (v) => _saveField(() => _repo.updateEnglish(widget.wordId, v)),
                    ),
                    _EditableTextField(
                      label: 'Bengali',
                      initialValue: bengali,
                      onSave: (v) => _saveField(() => _repo.updateBengali(widget.wordId, v)),
                    ),
                    _EditableTextField(
                      label: 'English note',
                      initialValue: englishNote,
                      multiline: true,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'englishNote': v.trim()})),
                    ),
                    _EditableTextField(
                      label: 'Bengali note',
                      initialValue: bengaliNote,
                      multiline: true,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'bengaliNote': v.trim()})),
                    ),
                    _EditableTextField(
                      label: 'category_main',
                      initialValue: categoryMain,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'category_main': v.trim()})),
                    ),
                    _EditableTextField(
                      label: 'category_sub',
                      initialValue: categorySub,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'category_sub': v.trim()})),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Synonyms / Antonyms',
                child: Column(
                  children: [
                    _EditableCsvListField(
                      label: 'englishWordSynonyms',
                      initialValues: englishSyn,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'englishWordSynonyms': v})),
                    ),
                    _EditableCsvListField(
                      label: 'bengaliWordSynonyms',
                      initialValues: bengaliSyn,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'bengaliWordSynonyms': v})),
                    ),
                    _EditableCsvListField(
                      label: 'englishWordAntonyms',
                      initialValues: englishAnt,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'englishWordAntonyms': v})),
                    ),
                    _EditableCsvListField(
                      label: 'bengaliWordAntonyms',
                      initialValues: bengaliAnt,
                      onSave: (v) => _saveField(() => _repo.updateFields(widget.wordId, {'bengaliWordAntonyms': v})),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Categories (advanced)',
                subtitle: 'Edit the full categories array as JSON.',
                child: _EditableJsonField(
                  label: 'categories',
                  initialJson: categoriesJson,
                  onSave: (decoded) => _saveField(() => _repo.updateFields(widget.wordId, {'categories': decoded})),
                ),
              ),
              _Section(
                title: 'Flashcard image',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(imageFlashcard.isEmpty ? '(empty)' : imageFlashcard),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _replaceMainFlashcard,
                          icon: const Icon(Icons.upload),
                          label: const Text('Replace flashcard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Variants',
                subtitle: 'Edit fields or replace media per variant. Changes are saved per action.',
                child: Column(
                  children: [
                    for (int i = 0; i < variants.length; i++)
                      _VariantCard(
                        index: i,
                        variant: variants[i],
                        onSaveLabel: (v) => _saveField(
                          () => _repo.updateVariantAtIndex(
                            wordId: widget.wordId,
                            index: i,
                            mutateVariant: (m) {
                              m['label'] = v.trim();
                              return m;
                            },
                          ),
                        ),
                        onSaveUrl: (field, v) => _saveField(
                          () => _repo.updateVariantAtIndex(
                            wordId: widget.wordId,
                            index: i,
                            mutateVariant: (m) {
                              m[field] = v.trim();
                              return m;
                            },
                          ),
                        ),
                        onReplaceVideo: () => _replaceVariantMedia(
                          index: i,
                          fieldKey: 'videoUrl',
                          storageDir: TenantStoragePaths.videosDir(conceptId: widget.wordId),
                          fileType: FileType.video,
                        ),
                        onReplaceVideoSD: () => _replaceVariantMedia(
                          index: i,
                          fieldKey: 'videoUrlSD',
                          storageDir: TenantStoragePaths.videosSdDir(conceptId: widget.wordId),
                          fileType: FileType.video,
                        ),
                        onReplaceVideoHD: () => _replaceVariantMedia(
                          index: i,
                          fieldKey: 'videoUrlHD',
                          storageDir: TenantStoragePaths.videosHdDir(conceptId: widget.wordId),
                          fileType: FileType.video,
                        ),
                        onReplaceThumb: () => _replaceVariantMedia(
                          index: i,
                          fieldKey: 'videoThumbnail',
                          storageDir: TenantStoragePaths.thumbnailsDir(conceptId: widget.wordId),
                          fileType: FileType.custom,
                          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                        ),
                        onReplaceThumbSmall: () => _replaceVariantMedia(
                          index: i,
                          fieldKey: 'videoThumbnailSmall',
                          storageDir: TenantStoragePaths.thumbnailsDir(conceptId: widget.wordId),
                          fileType: FileType.custom,
                          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.embedded) const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return Stack(
        children: [
          content,
          if (_busy)
            const Positioned(
              top: 8,
              right: 8,
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      );
    }

    return Stack(
      children: [
        content,
        if (_busy)
          Container(
            color: Colors.black.withValues(alpha: 0.05),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EditableTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool multiline;
  final Future<void> Function(String) onSave;

  const _EditableTextField({
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.multiline = false,
  });

  @override
  State<_EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<_EditableTextField> {
  bool _editing = false;
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.initialValue != widget.initialValue) {
      _c.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => setState(() => _editing = true),
                ),
            ],
          ),
          if (_editing) ...[
            TextField(
              controller: _c,
              maxLines: widget.multiline ? null : 1,
              minLines: widget.multiline ? 3 : 1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = false;
                      _c.text = widget.initialValue;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final v = _c.text;
                    await widget.onSave(v);
                    if (!mounted) return;
                    setState(() => _editing = false);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            SelectableText(widget.initialValue.isEmpty ? '(empty)' : widget.initialValue),
          ],
        ],
      ),
    );
  }
}

class _EditableCsvListField extends StatefulWidget {
  final String label;
  final List<String> initialValues;
  final Future<void> Function(List<String>) onSave;

  const _EditableCsvListField({
    required this.label,
    required this.initialValues,
    required this.onSave,
  });

  @override
  State<_EditableCsvListField> createState() => _EditableCsvListFieldState();
}

class _EditableCsvListFieldState extends State<_EditableCsvListField> {
  bool _editing = false;
  late final TextEditingController _c;

  String _toCsv(List<String> v) => v.join(', ');

  List<String> _fromCsv(String s) => s
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _toCsv(widget.initialValues));
  }

  @override
  void didUpdateWidget(covariant _EditableCsvListField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.initialValues != widget.initialValues) {
      _c.text = _toCsv(widget.initialValues);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => setState(() => _editing = true),
                ),
            ],
          ),
          if (_editing) ...[
            TextField(controller: _c, maxLines: null, minLines: 2),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _editing = false;
                      _c.text = _toCsv(widget.initialValues);
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final list = _fromCsv(_c.text);
                    await widget.onSave(list);
                    if (!mounted) return;
                    setState(() => _editing = false);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            SelectableText(widget.initialValues.isEmpty ? '(empty)' : widget.initialValues.join(', ')),
          ],
        ],
      ),
    );
  }
}

class _EditableJsonField extends StatefulWidget {
  final String label;
  final String initialJson;
  final Future<void> Function(dynamic decoded) onSave;

  const _EditableJsonField({
    required this.label,
    required this.initialJson,
    required this.onSave,
  });

  @override
  State<_EditableJsonField> createState() => _EditableJsonFieldState();
}

class _EditableJsonFieldState extends State<_EditableJsonField> {
  bool _editing = false;
  late final TextEditingController _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialJson);
  }

  @override
  void didUpdateWidget(covariant _EditableJsonField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.initialJson != widget.initialJson) {
      _c.text = widget.initialJson;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            if (!_editing)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => setState(() => _editing = true),
              ),
          ],
        ),
        if (_editing) ...[
          TextField(controller: _c, maxLines: 10),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _editing = false;
                    _error = null;
                    _c.text = widget.initialJson;
                  });
                },
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final decoded = jsonDecode(_c.text);
                    setState(() => _error = null);
                    await widget.onSave(decoded);
                    if (!mounted) return;
                    setState(() => _editing = false);
                  } catch (e) {
                    setState(() => _error = 'Invalid JSON: $e');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ] else ...[
          Text(widget.initialJson, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _VariantCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> variant;
  final Future<void> Function(String) onSaveLabel;
  final Future<void> Function(String field, String value) onSaveUrl;
  final VoidCallback onReplaceVideo;
  final VoidCallback onReplaceVideoSD;
  final VoidCallback onReplaceVideoHD;
  final VoidCallback onReplaceThumb;
  final VoidCallback onReplaceThumbSmall;

  const _VariantCard({
    required this.index,
    required this.variant,
    required this.onSaveLabel,
    required this.onSaveUrl,
    required this.onReplaceVideo,
    required this.onReplaceVideoSD,
    required this.onReplaceVideoHD,
    required this.onReplaceThumb,
    required this.onReplaceThumbSmall,
  });

  @override
  Widget build(BuildContext context) {
    final label = (variant['label'] ?? 'Version ${index + 1}').toString();
    final videoUrl = (variant['videoUrl'] ?? '').toString();
    final videoUrlSD = (variant['videoUrlSD'] ?? '').toString();
    final videoUrlHD = (variant['videoUrlHD'] ?? '').toString();
    final thumb = (variant['videoThumbnail'] ?? '').toString();
    final thumbSmall = (variant['videoThumbnailSmall'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Variant ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _InlineEdit(
              label: 'Label',
              initialValue: label,
              onSave: onSaveLabel,
            ),
            const SizedBox(height: 10),
            _UrlField(
              label: 'videoUrl',
              value: videoUrl,
              onSave: (v) => onSaveUrl('videoUrl', v),
              onReplace: onReplaceVideo,
            ),
            _UrlField(
              label: 'videoUrlSD',
              value: videoUrlSD,
              onSave: (v) => onSaveUrl('videoUrlSD', v),
              onReplace: onReplaceVideoSD,
            ),
            _UrlField(
              label: 'videoUrlHD',
              value: videoUrlHD,
              onSave: (v) => onSaveUrl('videoUrlHD', v),
              onReplace: onReplaceVideoHD,
            ),
            _UrlField(
              label: 'videoThumbnail',
              value: thumb,
              onSave: (v) => onSaveUrl('videoThumbnail', v),
              onReplace: onReplaceThumb,
            ),
            _UrlField(
              label: 'videoThumbnailSmall',
              value: thumbSmall,
              onSave: (v) => onSaveUrl('videoThumbnailSmall', v),
              onReplace: onReplaceThumbSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEdit extends StatefulWidget {
  final String label;
  final String initialValue;
  final Future<void> Function(String) onSave;

  const _InlineEdit({required this.label, required this.initialValue, required this.onSave});

  @override
  State<_InlineEdit> createState() => _InlineEditState();
}

class _InlineEditState extends State<_InlineEdit> {
  late final TextEditingController _c;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _InlineEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.initialValue != widget.initialValue) {
      _c.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(widget.label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: _editing
              ? TextField(
                  controller: _c,
                  decoration: const InputDecoration(isDense: true),
                )
              : Text(widget.initialValue.isEmpty ? '(empty)' : widget.initialValue),
        ),
        const SizedBox(width: 8),
        if (_editing) ...[
          IconButton(
            onPressed: () {
              setState(() {
                _editing = false;
                _c.text = widget.initialValue;
              });
            },
            icon: const Icon(Icons.close, size: 18),
          ),
          IconButton(
            onPressed: () async {
              await widget.onSave(_c.text);
              if (!mounted) return;
              setState(() => _editing = false);
            },
            icon: const Icon(Icons.check, size: 18),
          ),
        ] else ...[
          IconButton(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ],
    );
  }
}

class _UrlField extends StatelessWidget {
  final String label;
  final String value;
  final Future<void> Function(String) onSave;
  final VoidCallback onReplace;

  const _UrlField({
    required this.label,
    required this.value,
    required this.onSave,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              TextButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('Replace'),
              ),
            ],
          ),
          _InlineEdit(
            label: 'URL',
            initialValue: value,
            onSave: onSave,
          ),
        ],
      ),
    );
  }
}


