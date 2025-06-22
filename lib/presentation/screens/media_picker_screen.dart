import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/services/file_service.dart';
import '../../core/constants/app_constants.dart';

/// Screen for picking and sharing media files
class MediaPickerScreen extends StatefulWidget {
  final Function(File file, String type) onFileSelected;

  const MediaPickerScreen({
    super.key,
    required this.onFileSelected,
  });

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  final FileService _fileService = FileService();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      File? imageFile;
      
      if (source == ImageSource.gallery) {
        imageFile = await _fileService.pickImageFromGallery();
      } else {
        imageFile = await _fileService.takePhoto();
      }

      if (imageFile != null) {
        // Check file size
        if (!_fileService.isFileSizeValid(imageFile, AppConstants.maxImageSize)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image too large. Maximum size is ${_fileService.formatBytes(AppConstants.maxImageSize)}',
                ),
              ),
            );
          }
          return;
        }

        // Compress image
        final compressedImage = await _fileService.compressImage(imageFile);
        final finalImage = compressedImage ?? imageFile;

        widget.onFileSelected(finalImage, 'image');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickVideo(VideoSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      File? videoFile;
      
      if (source == VideoSource.gallery) {
        videoFile = await _fileService.pickVideoFromGallery();
      } else {
        videoFile = await _fileService.recordVideo();
      }

      if (videoFile != null) {
        // Check file size
        if (!_fileService.isFileSizeValid(videoFile, AppConstants.maxVideoSize)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Video too large. Maximum size is ${_fileService.formatBytes(AppConstants.maxVideoSize)}',
                ),
              ),
            );
          }
          return;
        }

        widget.onFileSelected(videoFile, 'video');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final file = await _fileService.pickFile();

      if (file != null) {
        // Check file size
        if (!_fileService.isFileSizeValid(file, AppConstants.maxFileSize)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File too large. Maximum size is ${_fileService.formatBytes(AppConstants.maxFileSize)}',
                ),
              ),
            );
          }
          return;
        }

        String fileType = 'file';
        if (_fileService.isImage(file)) {
          fileType = 'image';
        } else if (_fileService.isVideo(file)) {
          fileType = 'video';
        } else if (_fileService.isAudio(file)) {
          fileType = 'audio';
        }

        widget.onFileSelected(file, fileType);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Media'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Choose what to share',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Image Options
                  _buildSectionTitle('Photos', Icons.photo),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          icon: Icons.photo_library,
                          title: 'Gallery',
                          subtitle: 'Choose from gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionCard(
                          icon: Icons.camera_alt,
                          title: 'Camera',
                          subtitle: 'Take a photo',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Video Options
                  _buildSectionTitle('Videos', Icons.videocam),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          icon: Icons.video_library,
                          title: 'Gallery',
                          subtitle: 'Choose video',
                          onTap: () => _pickVideo(VideoSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionCard(
                          icon: Icons.videocam,
                          title: 'Record',
                          subtitle: 'Record video',
                          onTap: () => _pickVideo(VideoSource.camera),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // File Options
                  _buildSectionTitle('Files', Icons.attach_file),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    icon: Icons.folder,
                    title: 'Browse Files',
                    subtitle: 'Choose any file',
                    onTap: _pickFile,
                    isFullWidth: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Size Limits Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'File Size Limits',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Images: ${_fileService.formatBytes(AppConstants.maxImageSize)}\n'
                          '• Videos: ${_fileService.formatBytes(AppConstants.maxVideoSize)}\n'
                          '• Files: ${_fileService.formatBytes(AppConstants.maxFileSize)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageSource { gallery, camera }
enum VideoSource { gallery, camera }
