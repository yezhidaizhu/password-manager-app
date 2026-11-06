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
    this.backgroundAutoLock = true,
    this.privacyProtection = true,
    this.clipboardSeconds = 30,
  });

  final bool biometricEnabled;
  final int autoLockMinutes;
  final bool backgroundAutoLock;
  final bool privacyProtection;
  final int clipboardSeconds;

  VaultSettings copyWith({
    bool? biometricEnabled,
    int? autoLockMinutes,
    bool? backgroundAutoLock,
    bool? privacyProtection,
    int? clipboardSeconds,
  }) {
    return VaultSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      backgroundAutoLock: backgroundAutoLock ?? this.backgroundAutoLock,
      privacyProtection: privacyProtection ?? this.privacyProtection,
      clipboardSeconds: clipboardSeconds ?? this.clipboardSeconds,
    );
  }

  Map<String, Object?> toJson() => {
    'biometricEnabled': biometricEnabled,
    'autoLockMinutes': autoLockMinutes,
    'backgroundAutoLock': backgroundAutoLock,
    'privacyProtection': privacyProtection,
    'clipboardSeconds': clipboardSeconds,
  };

  factory VaultSettings.fromJson(Map<String, Object?>? json) {
    if (json == null) return const VaultSettings();
    return VaultSettings(
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoLockMinutes: json['autoLockMinutes'] as int? ?? 1,
      backgroundAutoLock: json['backgroundAutoLock'] as bool? ?? true,
      privacyProtection: json['privacyProtection'] as bool? ?? true,
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

  static const _vaultKey = 'keynest.encrypted-vault';
  static const _biometricKey = 'keynest.biometric-key';
  static const _deviceResetKey = 'keynest.device-reset-key';
  static const _legacyVaultKey = 'maobao.encrypted-vault';
  static const _legacyBiometricKey = 'maobao.biometric-key';

  final VaultCipher _cipher;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  SecretKey? _activeKey;
  VaultMetadata? _metadata;
  SecretKey? _pendingPasswordResetKey;

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<bool> hasVault() async {
    final preferences = await _preferences;
    await _migrateLegacyVault(preferences);
    return preferences.getString(_vaultKey) != null;
  }

  Future<VaultData> create(String password) async {
    final data = const VaultData(
      credentials: <Credential>[],
      settings: VaultSettings(),
    );
    final salt = _cipher.createSalt();
    final key = await _cipher.deriveKey(password, salt);
    final envelope = await _cipher.encryptWithKey(
      data.encode(),
      key,
      salt: salt,
      rounds: _cipher.iterations,
    );
    final metadata = _cipher.parseMetadata(envelope);
    _activeKey = key;
    _metadata = metadata;
    final preferences = await _preferences;
    await preferences.setString(_vaultKey, envelope);
    await _storeDeviceResetKey(_activeKey!);
    return data;
  }

  Future<VaultData> unlock(String password) async {
    final envelope = await _readEnvelope();
    final decrypted = await _cipher.decryptWithPassword(envelope, password);
    _activeKey = decrypted.key;
    _metadata = decrypted.metadata;
    await _storeDeviceResetKey(decrypted.key);
    return VaultData.decode(decrypted.clearText);
  }

  Future<bool> canUseDeviceAuthentication() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> hasDeviceResetKey() async {
    try {
      if (await _secureStorage.containsKey(key: _deviceResetKey)) return true;
      await _migrateLegacyBiometricKey();
      final biometricKey = await _secureStorage.read(key: _biometricKey);
      if (biometricKey == null) return false;
      await _secureStorage.write(key: _deviceResetKey, value: biometricKey);
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> beginPasswordReset() async {
    _pendingPasswordResetKey = null;
    try {
      final encodedKey = await _secureStorage.read(key: _deviceResetKey);
      if (encodedKey == null) return false;
      final authenticated = await _localAuth.authenticate(
        localizedReason: '验证手机身份以修改主密码',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!authenticated) return false;
      _pendingPasswordResetKey = SecretKey(base64Decode(encodedKey));
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on FormatException {
      return false;
    }
  }

  void cancelPasswordReset() {
    _pendingPasswordResetKey = null;
  }

  Future<VaultData> resetPassword(String password) async {
    final resetKey = _pendingPasswordResetKey;
    _pendingPasswordResetKey = null;
    if (resetKey == null) throw StateError('请先验证手机身份');

    final currentEnvelope = await _readEnvelope();
    final clearText = await _cipher.decryptWithKey(currentEnvelope, resetKey);
    final data = VaultData.decode(clearText);
    final salt = _cipher.createSalt();
    final newKey = await _cipher.deriveKey(password, salt);
    final newEnvelope = await _cipher.encryptWithKey(
      clearText,
      newKey,
      salt: salt,
      rounds: _cipher.iterations,
    );
    final newMetadata = _cipher.parseMetadata(newEnvelope);
    final preferences = await _preferences;
    await preferences.setString(_vaultKey, newEnvelope);
    _activeKey = newKey;
    _metadata = newMetadata;
    await _storeDeviceResetKey(newKey);
    if (await hasBiometricKey()) {
      await _secureStorage.write(
        key: _biometricKey,
        value: base64Encode(await newKey.extractBytes()),
      );
    }
    return data;
  }

  Future<VaultData?> unlockWithBiometrics() async {
    await _migrateLegacyBiometricKey();
    final encodedKey = await _secureStorage.read(key: _biometricKey);
    if (encodedKey == null) return null;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '验证身份以解锁 KeyNest',
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
      await _storeDeviceResetKey(key);
      return VaultData.decode(clearText);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<VaultData?> unlockWithDeviceAuthentication() async {
    final encodedKey = await _secureStorage.read(key: _deviceResetKey);
    if (encodedKey == null) return null;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '使用手机解锁 KeyNest',
        options: const AuthenticationOptions(stickyAuth: true),
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
      await _migrateLegacyBiometricKey();
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
    if (!await preferences.setString(_vaultKey, envelope)) {
      throw StateError('保险库保存失败');
    }
  }

  Future<bool> exportBackup() async {
    final envelope = await _readEnvelope();
    final fileName =
        'keynest-${DateTime.now().toIso8601String().substring(0, 10)}.keynest';
    final path = await FilePicker.saveFile(
      dialogTitle: '导出 KeyNest 加密备份',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['keynest'],
      bytes: Uint8List.fromList(utf8.encode(envelope)),
    );
    return path != null || kIsWeb;
  }

  Future<String?> pickBackup() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择 KeyNest 备份',
      type: FileType.custom,
      allowedExtensions: const ['keynest', 'maobao'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const FormatException('无法读取备份文件');
    if (bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('备份文件超过 20 MB');
    }
    final envelope = utf8.decode(bytes);
    _cipher.parseMetadata(envelope);
    return envelope;
  }

  Future<VaultData> validateBackup(String envelope, String password) async {
    final decrypted = await _cipher.decryptWithPassword(envelope, password);
    final raw = jsonDecode(decrypted.clearText);
    if (raw is! Map<String, dynamic> ||
        raw['version'] != 1 ||
        raw['credentials'] is! List ||
        (raw['settings'] != null && raw['settings'] is! Map)) {
      throw const FormatException('备份内容无效');
    }
    for (final item in raw['credentials'] as List) {
      if (item is! Map ||
          item['name'] is! String ||
          item['username'] is! String ||
          item['password'] is! String ||
          (item['tags'] != null &&
              (item['tags'] is! List ||
                  (item['tags'] as List).any((tag) => tag is! String)))) {
        throw const FormatException('备份包含无效记录');
      }
    }
    try {
      final data = VaultData.decode(decrypted.clearText);
      final ids = data.credentials.map((item) => item.id).toSet();
      if (ids.length != data.credentials.length) {
        throw const FormatException('备份包含重复记录编号');
      }
      return data;
    } on TypeError {
      throw const FormatException('备份数据格式无效');
    }
  }

  Future<void> importBackup(VaultData data) => save(data);

  Future<void> clear() async {
    final preferences = await _preferences;
    await preferences.remove(_vaultKey);
    await preferences.remove(_legacyVaultKey);
    await _secureStorage.delete(key: _biometricKey);
    await _secureStorage.delete(key: _deviceResetKey);
    await _secureStorage.delete(key: _legacyBiometricKey);
    lock();
  }

  void lock() {
    _activeKey = null;
    _metadata = null;
    _pendingPasswordResetKey = null;
  }

  Future<void> _storeDeviceResetKey(SecretKey key) async {
    if (!await canUseDeviceAuthentication()) return;
    try {
      await _secureStorage.write(
        key: _deviceResetKey,
        value: base64Encode(await key.extractBytes()),
      );
    } on PlatformException {
      // Password-based access remains available when secure storage fails.
    } on MissingPluginException {
      // Unsupported platforms continue without device-assisted reset.
    }
  }

  Future<String> _readEnvelope() async {
    final preferences = await _preferences;
    await _migrateLegacyVault(preferences);
    final envelope = preferences.getString(_vaultKey);
    if (envelope == null) throw StateError('保险库不存在');
    return envelope;
  }

  Future<void> _migrateLegacyVault(SharedPreferences preferences) async {
    if (preferences.getString(_vaultKey) != null) return;
    final legacyEnvelope = preferences.getString(_legacyVaultKey);
    if (legacyEnvelope == null) return;
    await preferences.setString(_vaultKey, legacyEnvelope);
    await preferences.remove(_legacyVaultKey);
  }

  Future<void> _migrateLegacyBiometricKey() async {
    if (await _secureStorage.containsKey(key: _biometricKey)) return;
    final legacyKey = await _secureStorage.read(key: _legacyBiometricKey);
    if (legacyKey == null) return;
    await _secureStorage.write(key: _biometricKey, value: legacyKey);
    await _secureStorage.delete(key: _legacyBiometricKey);
  }
}
