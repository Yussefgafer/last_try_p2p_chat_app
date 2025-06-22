import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

/// Helper class for encryption and decryption operations
class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  late final Encrypter _encrypter;
  late final IV _iv;

  /// Initialize encryption with a key
  void initialize(String keyString) {
    final key = Key.fromBase64(base64.encode(sha256.convert(utf8.encode(keyString)).bytes));
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16);
  }

  /// Generate a secure key from password
  static String generateKeyFromPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Encrypt text message
  String encryptText(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt text: $e');
    }
  }

  /// Decrypt text message
  String decryptText(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Failed to decrypt text: $e');
    }
  }

  /// Encrypt file data
  Uint8List encryptFile(Uint8List fileData) {
    try {
      final encrypted = _encrypter.encryptBytes(fileData, iv: _iv);
      return encrypted.bytes;
    } catch (e) {
      throw Exception('Failed to encrypt file: $e');
    }
  }

  /// Decrypt file data
  Uint8List decryptFile(Uint8List encryptedData) {
    try {
      final encrypted = Encrypted(encryptedData);
      return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
    } catch (e) {
      throw Exception('Failed to decrypt file: $e');
    }
  }

  /// Generate hash for data integrity
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify data integrity
  bool verifyHash(String data, String hash) {
    return generateHash(data) == hash;
  }

  /// Generate secure random key
  static String generateSecureKey() {
    final key = Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Generate IV for encryption
  String generateIV() {
    final iv = IV.fromSecureRandom(16);
    return iv.base64;
  }
}
