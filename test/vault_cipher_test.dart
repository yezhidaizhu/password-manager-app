import 'package:app_password_manager/services/vault_cipher.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypts and decrypts a vault payload', () async {
    final cipher = VaultCipher(iterations: 100);
    const payload = '{"version":1,"credentials":[]}';

    final envelope = await cipher.encryptWithPassword(payload, 'correct horse');
    final decrypted = await cipher.decryptWithPassword(
      envelope,
      'correct horse',
    );

    expect(decrypted.clearText, payload);
    expect(cipher.parseMetadata(envelope).salt, hasLength(32));
  });

  test('rejects an incorrect master password', () async {
    final cipher = VaultCipher(iterations: 100);
    final envelope = await cipher.encryptWithPassword(
      'secret',
      'right password',
    );

    expect(
      () => cipher.decryptWithPassword(envelope, 'wrong password'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
