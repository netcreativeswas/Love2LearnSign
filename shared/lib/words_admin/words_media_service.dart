import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WordsMediaService {
  // Canonical bucket used elsewhere in the project (see AddWordPage).
  static const String bucket = 'love-to-learn-sign.firebasestorage.app';

  Reference _root() => FirebaseStorage.instanceFor(bucket: bucket).ref();

  void _ensureAuthenticated() {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('User must be signed in to upload media.');
    }
  }

  static String _contentTypeFromExt(String extLower) {
    if (extLower.endsWith('.mp4')) return 'video/mp4';
    if (extLower.endsWith('.webp')) return 'image/webp';
    if (extLower.endsWith('.png')) return 'image/png';
    if (extLower.endsWith('.jpg') || extLower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<String> uploadPlatformFile(
    PlatformFile file, {
    required String storageDir,
  }) async {
    _ensureAuthenticated();

    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('Could not read file bytes for upload.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final original = file.name;
    final dotIndex = original.lastIndexOf('.');
    final base = dotIndex != -1 ? original.substring(0, dotIndex) : original;
    final ext = dotIndex != -1 ? original.substring(dotIndex) : '';
    final extLower = ext.toLowerCase();
    final newName = '${base}_$timestamp$ext';
    final objectPath = '$storageDir/$newName';

    return uploadBytes(
      bytes: bytes,
      objectPath: objectPath,
      contentType: _contentTypeFromExt(extLower),
    );
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String objectPath,
    required String contentType,
  }) async {
    _ensureAuthenticated();
    final ref = _root().child(objectPath);
    final meta = SettableMetadata(contentType: contentType);
    final snapshot = await ref.putData(bytes, meta);
    return await snapshot.ref.getDownloadURL();
  }
}


