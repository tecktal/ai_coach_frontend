import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileStorageService {
  /// Saves a recording file to the phone's Downloads or Documents directory
  /// Returns the path where the file was saved, or null if failed
  Future<String?> saveRecordingToPhone(String sourcePath, String filename) async {
    try {
      // Request storage permission (Android 10+)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return null;
          }
        }
      }

      // Get the appropriate directory
      Directory? targetDir;
      
      if (Platform.isAndroid) {
        // For Android, use Downloads directory
        targetDir = Directory('/storage/emulated/0/Download/AI_Coach_Recordings');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory (accessible via Files app)
        final appDocDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${appDocDir.path}/Recordings');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else {
        // Fallback for other platforms
        final appDocDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${appDocDir.path}/Recordings');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }

      // Copy the file
      final sourceFile = File(sourcePath);
      var targetPath = '${targetDir.path}/$filename';
      
      try {
        await sourceFile.copy(targetPath);
      } catch (e) {
        // Scoped storage on Android 11+ might block direct access to Downloads without SAF.
        // Fallback to app's own permanent documents directory which is guaranteed to succeed.
        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDocDir.path}/Recordings');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        targetPath = '${fallbackDir.path}/$filename';
        await sourceFile.copy(targetPath);
      }

      return targetPath;
    } catch (e) {
      print('File storage error: $e');
      return null;
    }
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      // Check manageExternalStorage for Android 11+
      final manageStatus = await Permission.manageExternalStorage.status;
      return manageStatus.isGranted;
    }
    // iOS doesn't need explicit permission for app documents
    return true;
  }
}
