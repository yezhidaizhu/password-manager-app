import 'dart:convert';

import 'package:app_password_manager/models/credential.dart';
import 'package:app_password_manager/services/vault_cipher.dart';
import 'package:app_password_manager/services/vault_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VaultCipher cipher;
  late VaultService service;
  late SharedPreferences preferences;
  late String original;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cipher = VaultCipher(iterations: 100);
    service = VaultService(cipher: cipher);
    await service.create('current-password');
    preferences = await SharedPreferences.getInstance();
    original = preferences.getString('keynest.encrypted-vault')!;
  });

  test(
    'wrong password and damaged ciphertext preserve the existing vault',
    () async {
      final envelope = await cipher.encryptWithPassword(
        const VaultData(credentials: [], settings: VaultSettings()).encode(),
        'backup-password',
      );
      await expectLater(
        service.validateBackup(envelope, 'wrong-password'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final damaged = jsonDecode(envelope) as Map<String, dynamic>;
      final bytes = base64Decode(damaged['box'] as String);
      bytes[15] ^= 1;
      damaged['box'] = base64Encode(bytes);
      await expectLater(
        service.validateBackup(jsonEncode(damaged), 'backup-password'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      expect(preferences.getString('keynest.encrypted-vault'), original);
    },
  );

  test('invalid records are rejected rather than silently discarded', () async {
    for (final records in [
      null,
      [42],
      [
        {'name': 'missing fields'},
      ],
    ]) {
      final envelope = await cipher.encryptWithPassword(
        jsonEncode({'version': 1, 'credentials': records}),
        'backup-password',
      );
      await expectLater(
        service.validateBackup(envelope, 'backup-password'),
        throwsFormatException,
      );
      expect(preferences.getString('keynest.encrypted-vault'), original);
    }
  });

  test(
    'validation does not write; restoring 100 records keeps the current password',
    () async {
      final records = List.generate(
        100,
        (i) => Credential(
          id: 'record-$i',
          name: '账号 $i',
          username: 'user$i',
          password: 'secret-$i',
        ),
      );
      final backup = VaultData(
        credentials: records,
        settings: const VaultSettings(),
      );
      final envelope = await cipher.encryptWithPassword(
        backup.encode(),
        'backup-password',
      );
      final validated = await service.validateBackup(
        envelope,
        'backup-password',
      );
      expect(preferences.getString('keynest.encrypted-vault'), original);
      await service.importBackup(validated);
      final saved = preferences.getString('keynest.encrypted-vault')!;
      final decrypted = await cipher.decryptWithPassword(
        saved,
        'current-password',
      );
      expect(VaultData.decode(decrypted.clearText).credentials, hasLength(100));
      await expectLater(
        cipher.decryptWithPassword(saved, 'backup-password'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    },
  );
}
