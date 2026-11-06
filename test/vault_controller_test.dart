import 'dart:async';

import 'package:app_password_manager/app.dart';
import 'package:app_password_manager/controllers/theme_controller.dart';
import 'package:app_password_manager/controllers/vault_controller.dart';
import 'package:app_password_manager/models/credential.dart';
import 'package:app_password_manager/services/vault_service.dart';
import 'package:app_password_manager/pages/vault_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service extends VaultService {
  final writes = <VaultData>[];
  final completions = <Completer<void>>[];

  @override
  Future<void> save(VaultData data) {
    writes.add(data);
    final completion = Completer<void>();
    completions.add(completion);
    return completion.future;
  }
}

Credential _credential(String id) =>
    Credential(id: id, name: id, username: 'user', password: 'secret');

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  testWidgets('home updates additions and pins before storage completes', (
    tester,
  ) async {
    final service = _Service();
    final controller = VaultController(service: service)
      ..status = VaultStatus.unlocked;
    final theme = ThemeController();
    addTearDown(controller.dispose);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: VaultShell(controller: controller, themeController: theme),
      ),
    );
    expect(find.text('还没有账号'), findsOneWidget);
    final added = controller.addCredential(_credential('example'));
    await tester.pump();
    expect(find.text('example'), findsOneWidget);
    service.completions.first.complete();
    await added;
    await tester.pump();
    await tester.tap(find.byTooltip('置顶'));
    await tester.pump();
    expect(find.byTooltip('取消置顶'), findsOneWidget);
    service.completions.last.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'updates before storage finishes and serializes rapid operations',
    () async {
      final service = _Service();
      final controller = VaultController(service: service)
        ..status = VaultStatus.unlocked;
      addTearDown(controller.dispose);
      var statusEvents = 0;
      controller.statusChanges.addListener(() => statusEvents++);
      final added = controller.addCredential(_credential('a'));
      final pinned = controller.togglePinned('a');
      await _flush();
      expect(controller.credentials.single.id, 'a');
      expect(service.writes.length, 1);
      service.completions.first.complete();
      expect(await added, isTrue);
      await _flush();
      expect(controller.credentials.single.pinned, isTrue);
      expect(service.writes.length, 2);
      service.completions.last.complete();
      expect(await pinned, isTrue);
      expect(service.writes.last.credentials.single.pinned, isTrue);
      expect(statusEvents, 0);
    },
  );

  test(
    'rolls back failed write before processing the next operation',
    () async {
      final service = _Service();
      final controller = VaultController(service: service)
        ..status = VaultStatus.unlocked;
      addTearDown(controller.dispose);
      controller.credentials = [_credential('a')];
      final pinned = controller.togglePinned('a');
      final added = controller.addCredential(_credential('b'));
      await _flush();
      expect(controller.credentials.single.pinned, isTrue);
      service.completions.first.completeError(StateError('disk full'));
      expect(await pinned, isFalse);
      await _flush();
      expect(controller.credentials.first.pinned, isFalse);
      expect(controller.credentials.map((item) => item.id), ['a', 'b']);
      service.completions.last.complete();
      expect(await added, isTrue);
      expect(service.writes.last.credentials.first.pinned, isFalse);
    },
  );

  test('reuses sorted data until credentials change', () {
    final controller = VaultController(service: _Service());
    addTearDown(controller.dispose);
    controller.credentials = [_credential('a')];
    final ordered = controller.orderedCredentials;
    final tags = controller.tags;
    expect(identical(controller.orderedCredentials, ordered), isTrue);
    expect(identical(controller.tags, tags), isTrue);
    controller.credentials = [...controller.credentials, _credential('b')];
    expect(identical(controller.orderedCredentials, ordered), isFalse);
    expect(controller.orderedCredentials.length, 2);
  });

  test(
    'locking cancels queued changes without restoring sensitive data',
    () async {
      final service = _Service();
      final controller = VaultController(service: service)
        ..status = VaultStatus.unlocked;
      addTearDown(controller.dispose);
      final first = controller.addCredential(_credential('a'));
      final second = controller.addCredential(_credential('b'));
      await _flush();
      controller.lock();
      service.completions.first.completeError(StateError('write failed'));
      expect(await first, isFalse);
      expect(await second, isFalse);
      expect(controller.credentials, isEmpty);
      expect(service.writes.length, 1);
    },
  );
}
