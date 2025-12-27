import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const String _cacheKey = 'videoCache';
  CacheManager? _manager;

  Future<CacheManager> _getManager() async {
    if (_manager != null) return _manager!;
    // Config notes: we prefer a generous object count and handle size separately.
    final config = Config(
      _cacheKey,
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 5000,
    );
    _manager = CacheManager(config);
    return _manager!;
  }

  Future<File?> getSingleFileRespectingSettings(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool('wifiOnly') ?? false;
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final onWifi = connectivity == ConnectivityResult.wifi;
      if (!onWifi) {
        // Avoid network download when not on Wi‑Fi; return cached file if present.
        final cm = await _getManager();
        final info = await cm.getFileFromCache(url);
        return info?.file;
      }
    }
    final cm = await _getManager();
    final file = await cm.getSingleFile(url);
    // Optionally prune after downloads to stay under size preference.
    _enforceMaxSizeIfNeeded();
    return file;
  }

  Future<File?> getFromCacheOnly(String url) async {
    final cm = await _getManager();
    final info = await cm.getFileFromCache(url);
    return info?.file;
  }

  Future<void> emptyCache() async {
    final cm = await _getManager();
    await cm.emptyCache();
  }

  Future<int> getApproxCacheSizeBytes() async {
    // Measure only this cache bucket for a more accurate size.
    final baseDir = await getTemporaryDirectory();
    final cacheDir = Directory('${baseDir.path}/$_cacheKey');
    if (await cacheDir.exists()) {
      return _directorySize(cacheDir);
    }
    // Fallback to temp dir if exact bucket not found
    return _directorySize(baseDir);
  }

  Future<void> _enforceMaxSizeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final maxMb = prefs.getInt('maxCacheSizeMb') ?? 500;
    if (maxMb <= 0) return;
    final bytes = await getApproxCacheSizeBytes();
    if (bytes <= maxMb * 1024 * 1024) return;

    // If over limit, remove oldest files from temp/cache dir until under limit.
    final baseDir = await getTemporaryDirectory();
    final dir = Directory('${baseDir.path}/$_cacheKey');
    final files = await _listFilesRecursively(dir);
    files.sort((a, b) {
      final at = a.statSync().modified;
      final bt = b.statSync().modified;
      return at.compareTo(bt); // oldest first
    });
    int total = bytes;
    for (final f in files) {
      try {
        total -= f.lengthSync();
        await f.delete();
        if (total <= maxMb * 1024 * 1024) break;
      } catch (_) {
        // ignore failures
      }
    }
  }

  Future<int> _directorySize(Directory dir) async {
    int total = 0;
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    }
    return total;
  }

  Future<List<File>> _listFilesRecursively(Directory dir) async {
    final out = <File>[];
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) out.add(entity);
      }
    }
    return out;
  }
}

