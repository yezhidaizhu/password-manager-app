import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/credential.dart';
import 'vault_cipher.dart';

class VaultSettings {
  const VaultSettings({
    this.biometricEnabled = false,
    this.autoLockMinutes = 1,
    this.clipboardSeconds = 30,
  });

  final bool biometricEnabled;
  final int autoLockMinutes;
  final int clipboardSeconds;

  VaultSettings copyWith({
    bool? biometricEnabled,
    int? autoLockMinutes,
    int? clipboardSeconds,
  }) {
    return VaultSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      clipboardSeconds: clipboardSeconds ?? this.clipboardSeconds,
    );
  }

  Map<String, Object?> toJson() => {
    'biometricEnabled': biometricEnabled,
    'autoLockMinutes': autoLockMinutes,
    'clipboardSeconds': clipboardSeconds,
  };

  factory VaultSettings.fromJson(Map<String, Object?>? json) {
    if (json == null) return const VaultSettings();
    return VaultSettings(
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoLockMinutes: json['autoLockMinutes'] as int? ?? 1,
      clipboardSeconds: json['clipboardSeconds'] as int? ?? 30,
    );
  }
}

class VaultData {
  const VaultData({required this.credentials, required this.settings});

  final List<Credential> credentials;
  final VaultSettings settings;

  String encode() => jsonEncode({
    'version': 1,
    'credentials': credentials.map((item) => item.toJson()).toList(),
    'settings': settings.toJson(),
  });

  factory VaultData.decode(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map<String, dynamic> || raw['version'] != 1) {
      throw const FormatException('保险库内容无效');
    }
    final credentialList = raw['credentials'];
    return VaultData(
      credentials: credentialList is List
          ? credentialList
                .whereType<Map>()
                .map(
                  (item) =>
                      Credential.fromJson(Map<String, Object?>.from(item)),
                )
                .toList()
          : <Credential>[],
      settings: VaultSettings.fromJson(
        raw['settings'] is Map
            ? Map<String, Object?>.from(raw['settings'] as Map)
            : null,
      ),
    );
  }
}

class VaultService {
  VaultService({VaultCipher? cipher}) : _cipher = cipher ?? VaultCipher();

  static const _vaultKey = 'maobao.encrypted-vault';
  static const _biometricKey = 'maobao.biometric-key';

  final VaultCipher _cipher;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  SecretKey? _activeKey;
  VaultMetadata? _metadata;

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<bool> hasVault() async {
    final preferences = await _preferences;
    return preferences.getString(_vaultKey) != null;
  }

  Future<VaultData> create(String password) async {
    final data = const VaultData(
      credentials: <Credential>[],
      settings: VaultSettings(),
    );
    final envelope = await _cipher.encryptWithPassword(data.encode(), password);
    final metadata = _cipher.parseMetadata(envelope);
    _activeKey = await _cipher.deriveKey(
      password,
      metadata.salt,
      rounds: metadata.iterations,
    );
    _metadata = metadata;
    final preferences = await _preferences;
    await preferences.setString(_vaultKey, envelope);
    return data;
  }

  Future<VaultData> unlock(String password) async {
    final envelope = await _readEnvelope();
    final decrypted = await _cipher.decryptWithPassword(envelope, password);
    _activeKey = decrypted.key;
    _metadata = decrypted.metadata;
    return VaultData.decode(decrypted.clearText);
  }

  Future<VaultData?> unlockWithBiometrics() async {
    final encodedKey = await _secureStorage.read(key: _biometricKey);
    if (encodedKey == null) return null;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '验证身份以解锁 MAOBAO',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!authenticated) return null;
      final key = SecretKey(base64Decode(encodedKey));
      final envelope = await _readEnvelope();
      final clearText = await _cipher.decryptWithKey(envelope, key);
      _activeKey = key;
      _metadata = _cipher.parseMetadata(envelope);
      return VaultData.decode(clearText);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> hasBiometricKey() async {
    try {
      return await _secureStorage.containsKey(key: _biometricKey);
    } on PlatformException {
      return false;
    }
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (!enabled) {
      await _secureStorage.delete(key: _biometricKey);
      return true;
    }
    final key = _activeKey;
    if (key == null || !await canUseBiometrics()) return false;
    final authenticated = await _localAuth.authenticate(
      localizedReason: '启用生物识别快捷解锁',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (!authenticated) return false;
    await _secureStorage.write(
      key: _biometricKey,
      value: base64Encode(await key.extractBytes()),
    );
    return true;
  }

  Future<void> save(VaultData data) async {
    final key = _activeKey;
    final metadata = _metadata;
    if (key == null || metadata == null) {
      throw StateError('保险库尚未解锁');
    }
    final envelope = await _cipher.encryptWithKey(
      data.encode(),
      key,
      salt: metadata.salt,
      rounds: metadata.iterations,
    );
    _metadata = _cipher.parseMetadata(envelope);
    final preferences = await _preferences;
    await preferences.setString(_vaultKey, envelope);
  }

  Future<bool> exportBackup() async {
    final envelope = await _readEnvelope();
    final fileName =
        'maobao-${DateTime.now().toIso8601String().substring(0, 10)}.maobao';
    final path = await FilePicker.saveFile(
      dialogTitle: '导出 MAOBAO 加密备份',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['maobao'],
      bytes: Uint8List.fromList(utf8.encode(envelope)),
    );
    return path != null || kIsWeb;
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 MAOBAO 备份',
      type: FileType.custom,
      allowedExtensions: const ['maobao'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const FormatException('无法读取备份文件');
    if (bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('备份文件超过 20 MB');
    }
    final envelope = utf8.decode(bytes);
    _cipher.parseMetadata(envelope);
    final preferences = await _preferences;
    await preferences.setString(_vaultKey, envelope);
    await _secureStorage.delete(key: _biometricKey);
    lock();
    return true;
  }

  Future<void> clear() async {
    final preferences = await _preferences;
    await preferences.remove(_vaultKey);
    await _secureStorage.delete(key: _biometricKey);
    lock();
  }

  void lock() {
    _activeKey = null;
    _metadata = null;
  }

  Future<String> _readEnvelope() async {
    final preferences = await _preferences;
    final envelope = preferences.getString(_vaultKey);
    if (envelope == null) throw StateError('保险库不存在');
    return envelope;
  }
}
