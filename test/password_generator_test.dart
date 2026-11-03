import 'package:app_password_manager/services/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('honors length and selected character groups', () {
    final generator = PasswordGenerator();
    final password = generator.generate(
      length: 24,
      upper: true,
      lower: true,
      numbers: true,
      symbols: true,
    );

    expect(password, hasLength(24));
    expect(password, matches(RegExp('[A-Z]')));
    expect(password, matches(RegExp('[a-z]')));
    expect(password, matches(RegExp('[0-9]')));
    expect(password, matches(RegExp(r'[!@#$%&*+\-=?_]')));
  });

  test('requires at least one character group', () {
    final generator = PasswordGenerator();
    expect(
      () => generator.generate(
        length: 16,
        upper: false,
        lower: false,
        numbers: false,
        symbols: false,
      ),
      throwsArgumentError,
    );
  });

  test('密码强度随长度和字符类型变化', () {
    final generator = PasswordGenerator();

    final weak = generator.strengthOf('abcdefgh');
    final strong = generator.strengthOf('Abcdefgh2345!@#%');

    expect(weak.label, '弱');
    expect(weak.level, 1);
    expect(strong.label, '很强');
    expect(strong.level, 4);
    expect(strong.value, greaterThan(weak.value));
  });
}
