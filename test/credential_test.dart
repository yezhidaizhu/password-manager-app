import 'package:app_password_manager/models/credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credential JSON round trip preserves encrypted payload fields', () {
    final original = Credential(
      id: 'credential-1',
      name: 'GitLab',
      username: 'dev@example.com',
      password: 'secret-password',
      website: 'https://gitlab.com',
      note: 'work',
      category: '工作',
      pinned: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    final decoded = Credential.fromJson(original.toJson());

    expect(decoded.id, original.id);
    expect(decoded.name, original.name);
    expect(decoded.username, original.username);
    expect(decoded.password, original.password);
    expect(decoded.website, original.website);
    expect(decoded.note, original.note);
    expect(decoded.category, original.category);
    expect(decoded.pinned, isTrue);
  });

  test('legacy favorite flag migrates to pinned', () {
    final decoded = Credential.fromJson({
      'name': 'Legacy',
      'username': 'user',
      'password': 'secret',
      'favorite': true,
    });

    expect(decoded.pinned, isTrue);
  });
}
