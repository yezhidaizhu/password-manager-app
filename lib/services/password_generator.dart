import 'dart:math';

class PasswordStrength {
  const PasswordStrength({
    required this.value,
    required this.level,
    required this.label,
  });

  final double value;
  final int level;
  final String label;
}

class PasswordGenerator {
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const _numbers = '23456789';
  static const _symbols = r'!@#$%&*+-=?_';

  PasswordStrength strengthOf(String password) {
    var poolSize = 0;
    if (password.contains(RegExp(r'[A-Z]'))) poolSize += _upper.length;
    if (password.contains(RegExp(r'[a-z]'))) poolSize += _lower.length;
    if (password.contains(RegExp(r'[0-9]'))) poolSize += _numbers.length;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      poolSize += _symbols.length;
    }

    if (password.isEmpty || poolSize == 0) {
      return const PasswordStrength(value: 0, level: 1, label: '弱');
    }

    final entropy = password.length * (log(poolSize) / ln2);
    final value = (entropy / 100).clamp(0.0, 1.0);
    final (level, label) = switch (entropy) {
      < 40 => (1, '弱'),
      < 60 => (2, '一般'),
      < 80 => (3, '强'),
      _ => (4, '很强'),
    };
    return PasswordStrength(value: value, level: level, label: label);
  }

  String generate({
    required int length,
    required bool upper,
    required bool lower,
    required bool numbers,
    required bool symbols,
  }) {
    final pools = <String>[
      if (upper) _upper,
      if (lower) _lower,
      if (numbers) _numbers,
      if (symbols) _symbols,
    ];
    if (pools.isEmpty) {
      throw ArgumentError('至少启用一种字符类型');
    }
    if (length < pools.length) {
      throw ArgumentError('密码长度过短');
    }

    final random = Random.secure();
    final characters = <String>[
      for (final pool in pools) pool[random.nextInt(pool.length)],
    ];
    final all = pools.join();
    while (characters.length < length) {
      characters.add(all[random.nextInt(all.length)]);
    }
    characters.shuffle(random);
    return characters.join();
  }
}
