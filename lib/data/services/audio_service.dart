import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../core/utils/uuid_helper.dart';
import '../../core/constants/app_constants.dart';

/// Service for audio recording and playback
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Logger _logger = Logger();
  
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  
  // Callbacks
  Function(Duration duration)? onRecordingProgress;
  Function(Duration duration)? onPlaybackProgress;
  Function()? onRecordingComplete;
  Function()? onPlaybackComplete;

  /// Initialize audio service
  Future<void> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize recorder
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;

      // Initialize player
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      _isPlayerInitialized = true;

      _logger.i('Audio service initialized');
    } catch (e) {
      _logger.e('Failed to initialize audio service: $e');
      throw Exception('Audio service initialization failed: $e');
    }
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (!_isRecorderInitialized) await initialize();

    try {
      if (_isRecording) {
        throw Exception('Already recording');
      }

      // Generate unique file path
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/audio_${UuidHelper.generateV4()}.aac';

      // Start recording
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;

      // Set up progress listener
      _recorder!.onProgress!.listen((event) {
        _recordingDuration = event.duration;
        onRecordingProgress?.call(_recordingDuration);
      });

      _logger.i('Started recording audio');
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording audio
  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      await _recorder!.stopRecorder();
      _isRecording = false;

      onRecordingComplete?.call();

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          _logger.i('Recording saved: $_currentRecordingPath');
          return file;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to stop recording: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder!.stopRecorder();
      _isRecording = false;

      // Delete the recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _recordingDuration = Duration.zero;

      _logger.i('Recording cancelled');
    } catch (e) {
      _logger.e('Failed to cancel recording: $e');
    }
  }

  /// Play audio file
  Future<void> playAudio(String filePath) async {
    if (!_isPlayerInitialized) await initialize();

    try {
      if (_isPlaying) {
        await stopPlayback();
      }

      await _player!.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
      );

      _isPlaying = true;

      // Set up progress listener
      _player!.onProgress!.listen((event) {
        onPlaybackProgress?.call(event.position);
        
        // Check if playback is complete
        if (event.position >= event.duration) {
          _isPlaying = false;
          onPlaybackComplete?.call();
        }
      });

      _logger.i('Started playing audio: $filePath');
    } catch (e) {
      _logger.e('Failed to play audio: $e');
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    if (!_isPlaying) return;

    try {
      await _player!.stopPlayer();
      _isPlaying = false;
      onPlaybackComplete?.call();
      _logger.i('Stopped audio playback');
    } catch (e) {
      _logger.e('Failed to stop playback: $e');
    }
  }

  /// Pause audio playback
  Future<void> pausePlayback() async {
    if (!_isPlaying) return;

    try {
      await _player!.pausePlayer();
      _logger.i('Paused audio playback');
    } catch (e) {
      _logger.e('Failed to pause playback: $e');
    }
  }

  /// Resume audio playback
  Future<void> resumePlayback() async {
    try {
      await _player!.resumePlayer();
      _logger.i('Resumed audio playback');
    } catch (e) {
      _logger.e('Failed to resume playback: $e');
    }
  }

  /// Get audio file duration
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      // This is a simplified implementation
      // In a real app, you might use a more sophisticated method
      final file = File(filePath);
      if (!await file.exists()) return null;

      // For now, return a placeholder duration
      // You can implement actual duration detection using audio metadata libraries
      return const Duration(seconds: 30);
    } catch (e) {
      _logger.e('Failed to get audio duration: $e');
      return null;
    }
  }

  /// Save audio file to app directory
  Future<File?> saveAudioFile(File sourceFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final fileName = 'audio_${UuidHelper.generateV4()}.aac';
      final targetPath = '${audioDir.path}/$fileName';
      final targetFile = await sourceFile.copy(targetPath);
      
      _logger.d('Audio file saved to: $targetPath');
      return targetFile;
    } catch (e) {
      _logger.e('Failed to save audio file: $e');
      return null;
    }
  }

  /// Check if file size is within audio limit
  bool isAudioSizeValid(File audioFile) {
    try {
      final fileSize = audioFile.lengthSync();
      return fileSize <= AppConstants.maxAudioSize;
    } catch (e) {
      _logger.e('Failed to check audio file size: $e');
      return false;
    }
  }

  /// Format duration to string
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get recording duration
  Duration get recordingDuration => _recordingDuration;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Check if currently playing
  bool get isPlaying => _isPlaying;

  /// Dispose audio service
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      
      if (_isPlaying) {
        await stopPlayback();
      }

      if (_isRecorderInitialized) {
        await _recorder!.closeRecorder();
        _isRecorderInitialized = false;
      }

      if (_isPlayerInitialized) {
        await _player!.closePlayer();
        _isPlayerInitialized = false;
      }

      // Clear callbacks
      onRecordingProgress = null;
      onPlaybackProgress = null;
      onRecordingComplete = null;
      onPlaybackComplete = null;

      _logger.i('Audio service disposed');
    } catch (e) {
      _logger.e('Error disposing audio service: $e');
    }
  }
}
