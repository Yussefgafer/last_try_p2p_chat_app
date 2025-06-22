import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/utils/uuid_helper.dart';

/// Service for handling file operations and media sharing
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final Logger _logger = Logger();
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to pick image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to take photo: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to pick video from gallery: $e');
      return null;
    }
  }

  /// Record video with camera
  Future<File?> recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to record video: $e');
      return null;
    }
  }

  /// Pick any file from system
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return File(file.path!);
        }
      }
      return null;
    } catch (e) {
      _logger.e('Failed to pick file: $e');
      return null;
    }
  }

  /// Pick multiple files
  Future<List<File>> pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to pick multiple files: $e');
      return [];
    }
  }

  /// Compress image
  Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${UuidHelper.generateV4()}.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 800,
        minHeight: 600,
      );
      
      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to compress image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Get file size in bytes
  int getFileSize(File file) {
    try {
      return file.lengthSync();
    } catch (e) {
      _logger.e('Failed to get file size: $e');
      return 0;
    }
  }

  /// Get file size formatted string
  String getFormattedFileSize(File file) {
    final bytes = getFileSize(file);
    return formatBytes(bytes);
  }

  /// Format bytes to human readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file extension
  String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// Get MIME type from file extension
  String getMimeType(File file) {
    final extension = getFileExtension(file);
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if file is image
  bool isImage(File file) {
    final mimeType = getMimeType(file);
    return mimeType.startsWith('image/');
  }

  /// Check if file is video
  bool isVideo(File file) {
    final mimeType = getMimeType(file);
    return mimeType.startsWith('video/');
  }

  /// Check if file is audio
  bool isAudio(File file) {
    final mimeType = getMimeType(file);
    return mimeType.startsWith('audio/');
  }

  /// Save file to app directory
  Future<File?> saveFileToAppDirectory(File sourceFile, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/files');
      
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }
      
      final targetPath = '${filesDir.path}/$fileName';
      final targetFile = await sourceFile.copy(targetPath);
      
      _logger.d('File saved to: $targetPath');
      return targetFile;
    } catch (e) {
      _logger.e('Failed to save file: $e');
      return null;
    }
  }

  /// Get saved files directory
  Future<Directory> getFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory('${appDir.path}/files');
    
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    
    return filesDir;
  }

  /// Delete file
  Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        _logger.d('File deleted: ${file.path}');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Failed to delete file: $e');
      return false;
    }
  }

  /// Read file as bytes
  Future<Uint8List?> readFileAsBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      _logger.e('Failed to read file as bytes: $e');
      return null;
    }
  }

  /// Write bytes to file
  Future<File?> writeBytesToFile(Uint8List bytes, String fileName) async {
    try {
      final filesDir = await getFilesDirectory();
      final file = File('${filesDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      _logger.d('Bytes written to file: ${file.path}');
      return file;
    } catch (e) {
      _logger.e('Failed to write bytes to file: $e');
      return null;
    }
  }

  /// Check if file size is within limit
  bool isFileSizeValid(File file, int maxSizeBytes) {
    final fileSize = getFileSize(file);
    return fileSize <= maxSizeBytes;
  }

  /// Get file name from path
  String getFileName(File file) {
    return file.path.split('/').last;
  }

  /// Generate unique file name
  String generateUniqueFileName(String originalName) {
    final extension = originalName.split('.').last;
    final nameWithoutExtension = originalName.substring(0, originalName.lastIndexOf('.'));
    final uuid = UuidHelper.generateShort();
    return '${nameWithoutExtension}_$uuid.$extension';
  }
}
