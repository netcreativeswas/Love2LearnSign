import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class PrefetchQueue {
  PrefetchQueue._();
  static final PrefetchQueue instance = PrefetchQueue._();

  final Queue<_PrefetchJob> _queue = Queue<_PrefetchJob>();
  final Map<String, Future<void>> _inFlightByUrl = {};
  int _running = 0;

  int get queued => _queue.length;
  int get running => _running;

  int get _concurrency {
    if (kIsWeb) return 2;
    // iOS tends to be more sensitive to background I/O + memory pressure.
    if (Platform.isIOS) return 2;
    return 3;
  }

  /// Enqueue a URL for best-effort disk caching.
  /// - De-duped by URL.
  /// - Concurrency-limited.
  Future<void> enqueue(
    String url, {
    bool Function()? isCancelled,
  }) {
    final u = url.trim();
    if (u.isEmpty) return Future.value();

    final existing = _inFlightByUrl[u];
    if (existing != null) return existing;

    final completer = Completer<void>();
    final future = completer.future;
    _inFlightByUrl[u] = future;

    _queue.add(_PrefetchJob(url: u, completer: completer, isCancelled: isCancelled));
    _pump();
    return future;
  }

  void _pump() {
    while (_running < _concurrency && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _running++;
      Future(() async {
        try {
          if (job.isCancelled?.call() == true) return;
          // If already cached, do nothing.
          final cached = await CacheService.instance.getFromCacheOnly(job.url);
          if (cached != null) return;
          // Otherwise, download to cache respecting user settings (wifiOnly).
          await CacheService.instance.getSingleFileRespectingSettings(job.url);
        } catch (_) {
          // Best-effort only.
        } finally {
          _running--;
          _inFlightByUrl.remove(job.url);
          if (!job.completer.isCompleted) job.completer.complete();
          // Continue pumping after finishing a job.
          _pump();
        }
      });
    }
  }
}

class _PrefetchJob {
  _PrefetchJob({
    required this.url,
    required this.completer,
    required this.isCancelled,
  });

  final String url;
  final Completer<void> completer;
  final bool Function()? isCancelled;
}

