import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/credential.dart';
import '../services/vault_service.dart';

enum VaultStatus { loading, needsSetup, locked, unlocked }

class VaultController extends ChangeNotifier {
  VaultController({VaultService? service})
    : _service = service ?? VaultService();

  final VaultService _service;
  VaultStatus status = VaultStatus.loading;
  List<Credential> credentials = <Credential>[];
  VaultSettings settings = const VaultSettings();
  bool biometricAvailable = false;
  bool biometricConfigured = false;
  bool busy = false;
  String? errorMessage;
  Timer? _clipboardTimer;

  Future<void> initialize() async {
    status = VaultStatus.loading;
    notifyListeners();
    biometricAvailable = await _service.canUseBiometrics();
    biometricConfigured = await _service.hasBiometricKey();
    final exists = await _service.hasVault();
    status = exists ? VaultStatus.locked : VaultStatus.needsSetup;
    notifyListeners();
  }

  Future<bool> createVault(
    String password, {
    bool enableBiometrics = false,
  }) async {
    return _guard(() async {
      final data = await _service.create(password);
      credentials = data.credentials;
      settings = data.settings;
      status = VaultStatus.unlocked;
      if (enableBiometrics && biometricAvailable) {
        final enabled = await _service.setBiometricEnabled(true);
        biometricConfigured = enabled;
        settings = settings.copyWith(biometricEnabled: enabled);
        await _persist();
      }
    });
  }

  Future<bool> unlock(String password) async {
    return _guard(() async {
      final data = await _service.unlock(password);
      _applyData(data);
      biometricConfigured = await _service.hasBiometricKey();
      status = VaultStatus.unlocked;
    }, invalidPasswordMessage: '主密码不正确');
  }

  Future<bool> unlockWithBiometrics() async {
    return _guard(() async {
      final data = await _service.unlockWithBiometrics();
      if (data == null) throw StateError('生物识别不可用或已取消');
      _applyData(data);
      biometricConfigured = true;
      status = VaultStatus.unlocked;
    });
  }

  void lock() {
    _service.lock();
    credentials = <Credential>[];
    status = VaultStatus.locked;
    notifyListeners();
  }

  Future<void> addCredential(Credential credential) async {
    credentials = [...credentials, credential];
    await _persist();
  }

  Future<void> updateCredential(Credential credential) async {
    credentials = [
      for (final item in credentials)
        if (item.id == credential.id) credential else item,
    ];
    await _persist();
  }

  Future<void> deleteCredential(String id) async {
    credentials = credentials.where((item) => item.id != id).toList();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    credentials = [
      for (final item in credentials)
        if (item.id == id) item.copyWith(favorite: !item.favorite) else item,
    ];
    await _persist();
  }

  Future<bool> setBiometricEnabled(bool value) async {
    final success = await _guard(() async {
      final enabled = await _service.setBiometricEnabled(value);
      if (!enabled && value) throw StateError('设备未完成生物识别验证');
      settings = settings.copyWith(biometricEnabled: value);
      biometricConfigured = value;
      await _persist();
    });
    return success;
  }

  Future<void> updateSecuritySettings({
    int? autoLockMinutes,
    int? clipboardSeconds,
  }) async {
    settings = settings.copyWith(
      autoLockMinutes: autoLockMinutes,
      clipboardSeconds: clipboardSeconds,
    );
    await _persist();
  }

  Future<void> copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(
      Duration(seconds: settings.clipboardSeconds),
      () async {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == value) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      },
    );
  }

  Future<bool> exportBackup() => _guardResult(_service.exportBackup);

  Future<bool> importBackup() async {
    final imported = await _guardResult(_service.importBackup);
    if (imported) {
      credentials = <Credential>[];
      settings = const VaultSettings();
      biometricConfigured = false;
      status = VaultStatus.locked;
      notifyListeners();
    }
    return imported;
  }

  Future<bool> clearVault() async {
    final cleared = await _guard(_service.clear);
    if (cleared) {
      credentials = <Credential>[];
      settings = const VaultSettings();
      biometricConfigured = false;
      status = VaultStatus.needsSetup;
      notifyListeners();
    }
    return cleared;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _service.save(
      VaultData(credentials: credentials, settings: settings),
    );
    notifyListeners();
  }

  void _applyData(VaultData data) {
    credentials = data.credentials;
    settings = data.settings;
  }

  Future<bool> _guard(
    Future<void> Function() action, {
    String? invalidPasswordMessage,
  }) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on SecretBoxAuthenticationError {
      errorMessage = invalidPasswordMessage ?? '加密数据验证失败';
      return false;
    } on FormatException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (error) {
      errorMessage = error is StateError
          ? error.message.toString()
          : '操作失败，请重试';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _guardResult(Future<bool> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on FormatException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = '操作失败，请重试';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }
}
