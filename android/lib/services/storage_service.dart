import 'dart:io';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String?> uploadFile({
    required String localPath,
    required String storagePath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint(
        'Storage upload skipped: local file does not exist: $localPath',
      );
      return null;
    }

    final ref = _storage.ref(storagePath);

    try {
      await ref.putFile(file);
      return _getDownloadUrlWithRetry(ref);
    } on FirebaseException catch (error) {
      debugPrint(
        'Storage upload warning for $storagePath: ${error.code} ${error.message}',
      );
      return null;
    } catch (error) {
      debugPrint('Storage upload warning for $storagePath: $error');
      return null;
    }
  }

  Future<String?> _getDownloadUrlWithRetry(Reference ref) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 250),
      Duration(milliseconds: 700),
    ];

    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          debugPrint(
            'Storage download url warning for ${ref.fullPath}: ${error.code} ${error.message}',
          );
          return null;
        }
      } catch (error) {
        debugPrint('Storage download url warning for ${ref.fullPath}: $error');
        return null;
      }
    }

    debugPrint(
      'Storage download url warning for ${ref.fullPath}: object not found after upload retries.',
    );
    return null;
  }

  Future<void> deleteByUrl(String url) async {
    if (!url.startsWith('http')) {
      return;
    }
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore orphaned references so delete stays resilient.
    }
  }
}
