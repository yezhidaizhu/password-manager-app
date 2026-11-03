import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class VaultCipher {
  VaultCipher({this.iterations = 600000});

  static const _format = 'keynest-v1';
  static const _legacyFormat = 'maobao-v1';

  final int iterations;
  final AesGcm _cipher = AesGcm.with256bits();

  List<int> createSalt([int length = 32]) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  Future<SecretKey> deriveKey(String password, List<int> salt, {int? rounds}) {
    return Pbkdf2.hmacSha256(
      iterations: rounds ?? iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<String> encryptWithPassword(String clearText, String password) async {
    final salt = createSalt();
    final key = await deriveKey(password, salt);
    return encryptWithKey(clearText, key, salt: salt, rounds: iterations);
  }

  Future<String> encryptWithKey(
    String clearText,
    SecretKey key, {
    required List<int> salt,
    required int rounds,
  }) async {
    final box = await _cipher.encrypt(
      utf8.encode(clearText),
      secretKey: key,
      nonce: _cipher.newNonce(),
    );
    return jsonEncode({
      'format': _format,
      'kdf': 'pbkdf2-sha256',
      'iterations': rounds,
      'salt': base64Encode(salt),
      'box': base64Encode(box.concatenation()),
    });
  }

  Future<DecryptedVault> decryptWithPassword(
    String envelope,
    String password,
  ) async {
    final metadata = parseMetadata(envelope);
    final key = await deriveKey(
      password,
      metadata.salt,
      rounds: metadata.iterations,
    );
    final clearText = await decryptWithKey(envelope, key);
    return DecryptedVault(clearText: clearText, key: key, metadata: metadata);
  }

  Future<String> decryptWithKey(String envelope, SecretKey key) async {
    final metadata = parseMetadata(envelope);
    final box = SecretBox.fromConcatenation(
      metadata.box,
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );
    final clearBytes = await _cipher.decrypt(box, secretKey: key);
    return utf8.decode(clearBytes);
  }

  VaultMetadata parseMetadata(String envelope) {
    final raw = jsonDecode(envelope);
    if (raw is! Map<String, dynamic> ||
        (raw['format'] != _format && raw['format'] != _legacyFormat)) {
      throw const FormatException('不是有效的 KeyNest 保险库');
    }
    final salt = base64Decode(raw['salt'] as String? ?? '');
    final box = base64Decode(raw['box'] as String? ?? '');
    final rounds = raw['iterations'] as int?;
    if (salt.length < 16 ||
        box.length < 32 ||
        rounds == null ||
        rounds < 1 ||
        rounds > 5000000) {
      throw const FormatException('保险库数据不完整');
    }
    return VaultMetadata(salt: salt, box: box, iterations: rounds);
  }
}

class VaultMetadata {
  const VaultMetadata({
    required this.salt,
    required this.box,
    required this.iterations,
  });

  final List<int> salt;
  final List<int> box;
  final int iterations;
}

class DecryptedVault {
  const DecryptedVault({
    required this.clearText,
    required this.key,
    required this.metadata,
  });

  final String clearText;
  final SecretKey key;
  final VaultMetadata metadata;
}
