import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file and return the download URL
  Future<String> uploadFile(String folder, File file) async {
    try {
      // Create a unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final filename = '$timestamp$extension';
      
      // Create reference to the file location
      final ref = _storage.ref().child(folder).child(filename);
      
      // Upload the file
      final uploadTask = await ref.putFile(file);
      
      // Get and return the download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload file: $e';
    }
  }

  // Delete a file using its URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: $e';
    }
  }

  // List all files in a folder
  Future<List<FileItem>> listFiles(String folder) async {
    try {
      final ListResult result = await _storage.ref().child(folder).listAll();
      
      List<FileItem> files = [];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        
        files.add(FileItem(
          name: item.name,
          url: url,
          size: metadata.size ?? 0,
          contentType: metadata.contentType ?? 'unknown',
          createdTime: metadata.timeCreated ?? DateTime.now(),
        ));
      }
      
      return files;
    } catch (e) {
      throw 'Failed to list files: $e';
    }
  }
}

class FileItem {
  final String name;
  final String url;
  final int size;
  final String contentType;
  final DateTime createdTime;

  FileItem({
    required this.name,
    required this.url,
    required this.size,
    required this.contentType,
    required this.createdTime,
  });

  // Convert file size to readable format
  String get readableSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = this.size.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
