import 'dart:io';

import 'package:flutter/material.dart';
import '../services/cache_service.dart';

class CachedThumb extends StatefulWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;

  const CachedThumb({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
  });

  @override
  State<CachedThumb> createState() => _CachedThumbState();
}

class _CachedThumbState extends State<CachedThumb> {
  File? _file;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void didUpdateWidget(covariant CachedThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = null;
      _started = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    final url = (widget.url ?? '').trim();
    if (url.isEmpty) return;
    try {
      final cached = await CacheService.instance.getThumbFromCacheOnly(url);
      if (!mounted) return;
      if (cached != null) {
        setState(() => _file = cached);
        return;
      }
      // Download to thumb cache in background; UI can still show Image.network meanwhile.
      final downloaded = await CacheService.instance.getThumbFile(url);
      if (!mounted) return;
      if (downloaded != null) setState(() => _file = downloaded);
    } catch (_) {
      // best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = (widget.url ?? '').trim();
    final placeholder = widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        );

    if (url.isEmpty) return placeholder;
    if (_file != null) {
      return Image.file(
        _file!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.error ?? placeholder,
      );
    }

    // First-run: show network image for fastest UX while we populate disk cache.
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => widget.error ?? placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
    );
  }
}

