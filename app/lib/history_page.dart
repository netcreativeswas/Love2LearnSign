import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/history_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:l2l_shared/tenancy/tenant_db.dart';
import 'l10n/dynamic_l10n.dart';
import 'video_viewer_page.dart';
import 'tenancy/tenant_scope.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  void _clearHistory() {
    context.read<HistoryRepository>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryRepository>().value;
    final tenantId = context.watch<TenantScope>().tenantId;
    return Builder(builder: (context) {
        if (history.isEmpty) {
          return Center(
            child: Text(
              S.of(context)!.noHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        return Stack(
          children: [
            FutureBuilder<QuerySnapshot>(
              future: TenantDb.concepts(FirebaseFirestore.instance, tenantId: tenantId)
                  .where(FieldPath.documentId, whereIn: history)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(
                    child: Text(
                      S.of(context)!.noHistory,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final docs = snapshot.data!.docs.where((doc) => doc.exists).toList();
                final docsMap = {for (var doc in docs) doc.id: doc};
                final orderedDocs = history.where((id) => docsMap.containsKey(id)).map((id) => docsMap[id]!).toList();
                return ListView.builder(
                  itemCount: orderedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = orderedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final english = data['english'] ?? '';
                    final bengali = data['bengali'] ?? '';
                    final wordId = doc.id;
                    final variants = data['variants'] as List<dynamic>? ?? [];
                    String? thumbnailUrl;
                    if (variants.isNotEmpty && variants[0] is Map && variants[0]['videoThumbnail'] != null) {
                      thumbnailUrl = variants[0]['videoThumbnail'];
                    }
                    return ListTile(
                      leading: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                thumbnailUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('assets/images/placeholder.png', width: 36, height: 36),
                              ),
                            )
                          : Image.asset('assets/images/placeholder.png', width: 36, height: 36),
                      title: Text(
                        '$english ($bengali)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: Icon(
                        Icons.play_arrow,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoViewerPage(wordId: wordId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: IconButton(
                iconSize: 32.0,
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _clearHistory,
                tooltip: S.of(context)!.clearHistoryTooltip,
              ),
            ),
          ],
        );
      },
    );
  }
}