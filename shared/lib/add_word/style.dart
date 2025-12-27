import 'package:flutter/material.dart';

class FieldBox extends StatelessWidget {
  final Widget child;

  const FieldBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }
}

class CategoryPicker extends StatefulWidget {
  final List<String> categories;
  final Map<String, List<String>> categoryToSubcategories;
  final String? selectedCategory;
  final String? selectedSubcategory;
  final void Function(String category, String? subcategory) onSelected;
  final bool enabled;
  final VoidCallback? onOpen;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.categoryToSubcategories,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.onSelected,
    this.enabled = true,
    this.onOpen,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  String? _hoveredCategory;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;
  final GlobalKey _anchorKey = GlobalKey();
  double? _anchorWidth;

  void _openMenu() {
    if (_menuOpen) return;
    final rb = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    _anchorWidth = rb?.size.width;
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _menuOpen = false;
      _hoveredCategory = null;
    });
  }

  OverlayEntry _buildOverlay() {
    final cs = Theme.of(context).colorScheme;
    return OverlayEntry(
      builder: (ctx) {
        String? expanded;
        return Stack(
          children: [
            // Dismiss area
            Positioned.fill(
              child: GestureDetector(onTap: _closeMenu, behavior: HitTestBehavior.opaque),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: StatefulBuilder(
                builder: (context, setSB) {
                  return Material(
                    elevation: 6,
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(6),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: (_anchorWidth ?? 260),
                        maxWidth: (_anchorWidth ?? 260),
                        maxHeight: 360,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: widget.categories.map((cat) {
                          final subs = widget.categoryToSubcategories[cat] ?? const [];
                          final hasSubs = subs.isNotEmpty;
                          final isExpanded = expanded == cat;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  // Select main category immediately, even if it has subcategories
                                  widget.onSelected(cat, null);
                                  _closeMenu();
                                },
                                onHover: (h) => setState(() => _hoveredCategory = h ? cat : null),
                                child: Builder(
                                  builder: (rowCtx) => Container(
                                    color: _hoveredCategory == cat
                                        ? cs.onSurface.withValues(alpha: 0.05)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(cat, style: const TextStyle(fontSize: 12))),
                                          if (hasSubs)
                                            InkWell(
                                              onTap: () {
                                                // Expand/collapse subcategories and trigger the same scroll behavior as opening the menu
                                                widget.onOpen?.call();
                                                setSB(() => expanded = isExpanded ? null : cat);
                                                // After expansion, scroll the row to the top so sub-list is fully visible
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  Scrollable.ensureVisible(
                                                    rowCtx,
                                                    alignment: 0.0,
                                                    duration: const Duration(milliseconds: 250),
                                                    curve: Curves.easeOut,
                                                  );
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Icon(
                                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_right,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (hasSubs && isExpanded)
                                Container(
                                  margin: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    children: subs
                                        .map(
                                          (s) => InkWell(
                                            onTap: () {
                                              widget.onSelected(cat, s);
                                              _closeMenu();
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              child: Text(s, style: const TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: InkWell(
            onTap: () {
              if (!widget.enabled || widget.categories.isEmpty) return;
              if (_menuOpen) {
                _closeMenu();
              } else {
                widget.onOpen?.call();
                _openMenu();
              }
            },
            child: Container(
              key: _anchorKey,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedCategory == null
                          ? (widget.enabled && widget.categories.isNotEmpty
                              ? 'Select a category'
                              : 'Loading categories…')
                          : widget.selectedSubcategory == null
                              ? widget.selectedCategory!
                              : '${widget.selectedCategory}  >  ${widget.selectedSubcategory}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

