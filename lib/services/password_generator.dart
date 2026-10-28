import 'dart:math';

class PasswordGenerator {
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const _numbers = '23456789';
  static const _symbols = r'!@#$%&*+-=?_';

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
