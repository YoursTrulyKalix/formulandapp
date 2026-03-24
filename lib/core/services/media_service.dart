import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for uploading media files to Firebase Storage
class MediaService {
  MediaService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a single media file and returns the download URL
  /// 
  /// [file] — The File to upload
  /// [userId] — The current user's ID (for organizing uploads)
  /// 
  /// Throws FirebaseException if upload fails
  static Future<String> uploadMedia(File file, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.path.split('/').last;
      final storagePath = 'posts/$userId/$timestamp-$fileName';

      final ref = _storage.ref(storagePath);
      await ref.putFile(file);
      
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Uploads media bytes and returns the download URL (works on web and native)
  /// 
  /// [bytes] — The file bytes to upload
  /// [fileName] — The file name
  /// [userId] — The current user's ID (for organizing uploads)
  /// 
  /// Throws FirebaseException if upload fails
  static Future<String> uploadMediaBytes(
      List<int> bytes, String fileName, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'posts/$userId/$timestamp-$fileName';

      final ref = _storage.ref(storagePath);
      
      final uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: _getMimeType(fileName)),
      );
      
      // Wait with generous timeout (5 minutes for web)
      final snapshot = await uploadTask.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('Upload took too long', const Duration(minutes: 5)),
      );
      
      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(minutes: 1),
        onTimeout: () => throw TimeoutException('Getting URL took too long', const Duration(minutes: 1)),
      );
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Determines MIME type from file name
  static String _getMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image/$ext';
    }
    if (['mp4', 'mkv', 'webm', 'avi'].contains(ext)) {
      return 'video/$ext';
    }
    if (ext == 'mov') return 'video/quicktime';
    return 'application/octet-stream';
  }

  /// Uploads multiple media files in parallel and returns list of download URLs
  /// 
  /// [files] — List of files to upload (max 10)
  /// [userId] — The current user's ID
  /// 
  /// Returns a list of download URLs in the same order as the input files.
  /// If a single upload fails, the batch fails and throws an exception.
  static Future<List<String>> uploadMediaBatch(
      List<File> files, String userId) async {
    if (files.isEmpty) return [];
    if (files.length > 10) throw Exception('Maximum 10 files per batch');

    try {
      final uploadTasks = files
          .map((file) => uploadMedia(file, userId))
          .toList();

      final downloadUrls = await Future.wait(uploadTasks);
      return downloadUrls;
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a media file from Firebase Storage by its download URL
  /// 
  /// This is useful for cleanup if a post is deleted.
  static Future<void> deleteMedia(String downloadUrl) async {
    try {
      // Extract the path from the download URL
      // Firebase download URLs have format:
      // https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile?alt=media&token=xyz
      
      final uri = Uri.parse(downloadUrl);
      final pathParts = uri.pathSegments;
      
      if (pathParts.length < 4) {
        throw Exception('Invalid download URL format');
      }

      // The file path is in the 'o' parameter, URL-encoded
      final encodedPath = pathParts[4]; // After /b/bucket/o/
      final decodedPath = Uri.decodeComponent(encodedPath);

      final ref = _storage.ref(decodedPath);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the current user ID, throws if not authenticated
  static String getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }
}
