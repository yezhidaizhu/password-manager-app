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
  final ValueNotifier<VaultStatus> statusChanges = ValueNotifier(
    VaultStatus.loading,
  );
  final ChangeNotifier credentialChanges = ChangeNotifier();
  VaultStatus get status => statusChanges.value;
  set status(VaultStatus value) => statusChanges.value = value;
  List<Credential> _credentials = const [];
  List<Credential>? _orderedCache;
  List<String>? _tagsCache;
  List<Credential> get credentials => _credentials;
  set credentials(List<Credential> value) {
    _credentials = List.unmodifiable(value);
    _orderedCache = null;
    _tagsCache = null;
    credentialChanges.notifyListeners();
  }

  Future<void> _mutationTail = Future.value();
  Future<void> _saveTail = Future.value();
  int _session = 0;
  bool _disposed = false;
  VaultSettings settings = const VaultSettings();
  bool biometricAvailable = false;
  bool biometricConfigured = false;
  bool deviceAuthenticationAvailable = false;
  bool passwordResetAvailable = false;
  bool busy = false;
  String? errorMessage;
  Timer? _clipboardTimer;

  List<Credential> get orderedCredentials {
    if (_orderedCache != null) return _orderedCache!;
    final ordered = [...credentials];
    ordered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return _orderedCache = List.unmodifiable(ordered);
  }

  List<String> get tags {
    if (_tagsCache != null) return _tagsCache!;
    final values = credentials
        .expand((item) => item.tags)
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty && tag != '全部')
        .toSet()
        .toList();
    values.sort();
    return _tagsCache = List.unmodifiable(values);
  }

  Future<void> initialize() async {
    status = VaultStatus.loading;
    notifyListeners();
    biometricAvailable = await _service.canUseBiometrics();
    biometricConfigured = await _service.hasBiometricKey();
    deviceAuthenticationAvailable = await _service.canUseDeviceAuthentication();
    passwordResetAvailable =
        deviceAuthenticationAvailable && await _service.hasDeviceResetKey();
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
      passwordResetAvailable = await _service.hasDeviceResetKey();
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
      passwordResetAvailable = await _service.hasDeviceResetKey();
      status = VaultStatus.unlocked;
    }, invalidPasswordMessage: '主密码不正确');
  }

  Future<bool> unlockWithBiometrics() async {
    return _guard(() async {
      final data = await _service.unlockWithBiometrics();
      if (data == null) throw StateError('生物识别不可用或已取消');
      _applyData(data);
      biometricConfigured = true;
      passwordResetAvailable = await _service.hasDeviceResetKey();
      status = VaultStatus.unlocked;
    });
  }

  Future<bool> unlockWithDeviceAuthentication() async {
    return _guard(() async {
      final data = await _service.unlockWithDeviceAuthentication();
      if (data == null) throw StateError('手机解锁未通过');
      _applyData(data);
      biometricConfigured = await _service.hasBiometricKey();
      passwordResetAvailable = true;
      status = VaultStatus.unlocked;
    });
  }

  Future<bool> beginPasswordReset() async {
    return _guard(() async {
      final authenticated = await _service.beginPasswordReset();
      if (!authenticated) throw StateError('无法验证手机身份');
    });
  }

  void cancelPasswordReset() {
    _service.cancelPasswordReset();
  }

  Future<bool> resetPassword(String password) async {
    return _guard(() async {
      final data = await _service.resetPassword(password);
      _applyData(data);
      biometricConfigured = await _service.hasBiometricKey();
      passwordResetAvailable = await _service.hasDeviceResetKey();
      status = VaultStatus.unlocked;
    });
  }

  void lock({bool preserveView = false}) {
    _session++;
    _service.lock();
    // Keep the covered page's data stable while its route and draft are retained.
    if (!preserveView) credentials = <Credential>[];
    status = VaultStatus.locked;
    notifyListeners();
  }

  Future<bool> addCredential(Credential credential) =>
      _mutateCredentials((items) => [...items, credential]);

  Future<bool> updateCredential(Credential credential) => _mutateCredentials(
    (items) => [
      for (final item in items)
        if (item.id == credential.id) credential else item,
    ],
  );

  Future<bool> deleteCredential(String id) => _mutateCredentials(
    (items) => items.where((item) => item.id != id).toList(),
  );

  Future<bool> togglePinned(String id) => _mutateCredentials(
    (items) => [
      for (final item in items)
        if (item.id == id) item.copyWith(pinned: !item.pinned) else item,
    ],
  );

  Future<bool> _mutateCredentials(
    List<Credential> Function(List<Credential>) change,
  ) {
    if (busy) return Future.value(false);
    final session = _session;
    final operation = _mutationTail.then((_) async {
      if (_disposed || session != _session || status != VaultStatus.unlocked)
        return false;
      final previous = credentials;
      errorMessage = null;
      credentials = change(previous);
      try {
        await _persist(notify: false);
        return true;
      } catch (_) {
        if (!_disposed && session == _session) {
          errorMessage = '保存失败，已恢复原数据，请重试';
          credentials = previous;
          notifyListeners();
        }
        return false;
      }
    });
    _mutationTail = operation.then<void>((_) {});
    return operation;
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
    bool? backgroundAutoLock,
    bool? privacyProtection,
    int? clipboardSeconds,
  }) async {
    settings = settings.copyWith(
      autoLockMinutes: autoLockMinutes,
      backgroundAutoLock: backgroundAutoLock,
      privacyProtection: privacyProtection,
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

  Future<String?> pickBackup() async {
    String? envelope;
    await _guard(() async {
      envelope = await _service.pickBackup();
    });
    return envelope;
  }

  final _unlockWaiters = <Completer<bool>>{};

  Future<bool> waitForUnlock() async {
    if (status == VaultStatus.unlocked) return true;
    if (_disposed || status != VaultStatus.locked) return false;
    final waiter = Completer<bool>();
    void check() {
      if (status != VaultStatus.locked && !waiter.isCompleted) {
        waiter.complete(status == VaultStatus.unlocked);
      }
    }

    _unlockWaiters.add(waiter);
    statusChanges.addListener(check);
    try {
      return await waiter.future;
    } finally {
      _unlockWaiters.remove(waiter);
      if (!_disposed) statusChanges.removeListener(check);
    }
  }

  Future<VaultData?> validateBackup(String envelope, String password) async {
    VaultData? data;
    await _guard(() async {
      data = await _service.validateBackup(envelope, password);
    }, invalidPasswordMessage: '备份主密码不正确，或文件已损坏');
    return data;
  }

  Future<bool> importBackup(VaultData data) => _guard(() async {
    if (status != VaultStatus.unlocked) throw StateError('请先解锁保险库');
    final restored = VaultData(
      credentials: data.credentials,
      settings: data.settings.copyWith(biometricEnabled: biometricConfigured),
    );
    await _service.importBackup(restored);
    _applyData(restored);
  });

  Future<bool> clearVault() async {
    final cleared = await _guard(_service.clear);
    if (cleared) {
      credentials = <Credential>[];
      settings = const VaultSettings();
      biometricConfigured = false;
      passwordResetAvailable = false;
      status = VaultStatus.needsSetup;
      notifyListeners();
    }
    return cleared;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _persist({bool notify = true}) {
    final data = VaultData(credentials: credentials, settings: settings);
    final operation = _saveTail.then((_) => _service.save(data));
    _saveTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation.then((_) {
      if (!_disposed && notify) notifyListeners();
    });
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
      await _mutationTail;
      await _saveTail;
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
      await _mutationTail;
      await _saveTail;
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
    _disposed = true;
    for (final waiter in _unlockWaiters) {
      if (!waiter.isCompleted) waiter.complete(false);
    }
    _session++;
    _clipboardTimer?.cancel();
    statusChanges.dispose();
    credentialChanges.dispose();
    super.dispose();
  }
}
