import 'dart:io' show Directory, File, Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:file/file.dart' as file_pkg;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// iOS optimization: avoid caching under iOS tmp (which is aggressively purged).
/// Store cache files under Library/Caches/{key} instead.
class _L2LCacheFileSystem implements FileSystem {
  final Future<file_pkg.Directory> _fileDir;
  final String _cacheKey;

  _L2LCacheFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);

  static Future<file_pkg.Directory> createDirectory(String key) async {
    final base = await _baseDirPathForKey(key);
    const fs = LocalFileSystem();
    final directory = fs.directory(base);
    await directory.create(recursive: true);
    return directory;
  }

  static Future<String> _baseDirPathForKey(String key) async {
    if (!kIsWeb && Platform.isIOS) {
      final lib = await getLibraryDirectory(); // .../Library
      // Library/Caches is not backed up and is more persistent than tmp.
      return p.join(lib.path, 'Caches', key);
    }
    // Keep current behavior on other platforms (tmp/<key>).
    final tmp = await getTemporaryDirectory();
    return p.join(tmp.path, key);
  }

  @override
  Future<file_pkg.File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }
    const fs = LocalFileSystem();
    return fs.file(p.join(directory.path, name));
  }
}

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const String _videoCacheKey = 'videoCache';
  static const String _thumbCacheKey = 'thumbCache';
  CacheManager? _videoManager;
  CacheManager? _thumbManager;

  Future<CacheManager> _getVideoManager() async {
    if (_videoManager != null) return _videoManager!;
    // Config notes: we prefer a generous object count and handle size separately.
    final config = Config(
      _videoCacheKey,
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 5000,
      fileSystem: _L2LCacheFileSystem(_videoCacheKey),
    );
    _videoManager = CacheManager(config);
    return _videoManager!;
  }

  Future<CacheManager> _getThumbManager() async {
    if (_thumbManager != null) return _thumbManager!;
    final config = Config(
      _thumbCacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 5000,
      fileSystem: _L2LCacheFileSystem(_thumbCacheKey),
    );
    _thumbManager = CacheManager(config);
    return _thumbManager!;
  }

  Future<File?> getSingleFileRespectingSettings(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool('wifiOnly') ?? false;
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final onWifi = connectivity == ConnectivityResult.wifi;
      if (!onWifi) {
        // Avoid network download when not on Wi‑Fi; return cached file if present.
        final cm = await _getVideoManager();
        final info = await cm.getFileFromCache(url);
        return info?.file;
      }
    }
    final cm = await _getVideoManager();
    final file = await cm.getSingleFile(url);
    // Optionally prune after downloads to stay under size preference.
    _enforceMaxSizeIfNeeded();
    return file;
  }

  Future<File?> getFromCacheOnly(String url) async {
    final cm = await _getVideoManager();
    final info = await cm.getFileFromCache(url);
    return info?.file;
  }

  Future<File?> getThumbFile(String url) async {
    final cm = await _getThumbManager();
    final file = await cm.getSingleFile(url);
    return file;
  }

  Future<File?> getThumbFromCacheOnly(String url) async {
    final cm = await _getThumbManager();
    final info = await cm.getFileFromCache(url);
    return info?.file;
  }

  Future<void> emptyCache() async {
    final cm = await _getVideoManager();
    await cm.emptyCache();
  }

  Future<void> emptyThumbCache() async {
    final cm = await _getThumbManager();
    await cm.emptyCache();
  }

  Future<String> getVideoCacheDirPath() async => (await _videoCacheDir()).path;

  Future<String> getThumbCacheDirPath() async => (await _thumbCacheDir()).path;

  Future<int> getVideoCacheFileCount() async {
    final dir = await _videoCacheDir();
    final files = await _listFilesRecursively(dir);
    return files.length;
  }

  Future<int> getThumbCacheFileCount() async {
    final dir = await _thumbCacheDir();
    final files = await _listFilesRecursively(dir);
    return files.length;
  }

  Future<String?> getLastVideoPruneAtIso() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('videoCacheLastPruneAtIso');
    return (v != null && v.trim().isNotEmpty) ? v : null;
  }

  Future<Directory> _videoCacheDir() async {
    final path = await _L2LCacheFileSystem._baseDirPathForKey(_videoCacheKey);
    return Directory(path);
  }

  Future<Directory> _thumbCacheDir() async {
    final path = await _L2LCacheFileSystem._baseDirPathForKey(_thumbCacheKey);
    return Directory(path);
  }

  Future<int> getApproxCacheSizeBytes() async {
    // Measure only this cache bucket for a more accurate size.
    final cacheDir = await _videoCacheDir();
    if (await cacheDir.exists()) {
      return _directorySize(cacheDir);
    }
    // Fallback: measure base dir (best-effort).
    return 0;
  }

  Future<int> getApproxThumbCacheSizeBytes() async {
    final cacheDir = await _thumbCacheDir();
    if (await cacheDir.exists()) {
      return _directorySize(cacheDir);
    }
    return 0;
  }

  Future<void> _enforceMaxSizeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final maxMb = prefs.getInt('maxCacheSizeMb') ?? 500;
    if (maxMb <= 0) return;
    final bytes = await getApproxCacheSizeBytes();
    if (bytes <= maxMb * 1024 * 1024) return;

    // If over limit, remove oldest files from temp/cache dir until under limit.
    final dir = await _videoCacheDir();
    final files = await _listFilesRecursively(dir);
    files.sort((a, b) {
      final at = a.statSync().modified;
      final bt = b.statSync().modified;
      return at.compareTo(bt); // oldest first
    });
    int total = bytes;
    var deletedAny = false;
    for (final f in files) {
      try {
        total -= f.lengthSync();
        await f.delete();
        deletedAny = true;
        if (total <= maxMb * 1024 * 1024) break;
      } catch (_) {
        // ignore failures
      }
    }
    if (deletedAny) {
      try {
        await prefs.setString(
          'videoCacheLastPruneAtIso',
          DateTime.now().toUtc().toIso8601String(),
        );
      } catch (_) {}
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

