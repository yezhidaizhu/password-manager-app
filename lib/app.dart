import 'dart:async';

import 'package:flutter/material.dart';

import 'controllers/vault_controller.dart';
import 'pages/unlock_page.dart';
import 'pages/vault_shell.dart';
import 'theme/app_theme.dart';

export 'theme/app_theme.dart';

class MaobaoApp extends StatefulWidget {
  const MaobaoApp({super.key});

  @override
  State<MaobaoApp> createState() => _MaobaoAppState();
}

class _MaobaoAppState extends State<MaobaoApp> with WidgetsBindingObserver {
  final VaultController _controller = VaultController();
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller.status != VaultStatus.unlocked) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _lockTimer?.cancel();
      _lockTimer = Timer(
        Duration(minutes: _controller.settings.autoLockMinutes),
        _controller.lock,
      );
    } else if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAOBAO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return switch (_controller.status) {
            VaultStatus.loading => const _LoadingPage(),
            VaultStatus.needsSetup => SetupPage(controller: _controller),
            VaultStatus.locked => UnlockPage(controller: _controller),
            VaultStatus.unlocked => VaultShell(controller: _controller),
          };
        },
      ),
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFF00110D),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/unlock_background.png', fit: BoxFit.cover),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
