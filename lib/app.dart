import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/theme_controller.dart';
import 'controllers/vault_controller.dart';
import 'pages/unlock_page.dart';
import 'pages/vault_shell.dart';
import 'theme/app_theme.dart';

export 'theme/app_theme.dart';

class KeyNestApp extends StatefulWidget {
  const KeyNestApp({super.key});

  @override
  State<KeyNestApp> createState() => _KeyNestAppState();
}

class _KeyNestAppState extends State<KeyNestApp> with WidgetsBindingObserver {
  final VaultController _controller = VaultController();
  final ThemeController _themeController = ThemeController();
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
    _themeController.initialize();
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
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'KeyNest',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.mode,
          home: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return switch (_controller.status) {
                VaultStatus.loading => const _LoadingPage(),
                VaultStatus.needsSetup => SetupPage(controller: _controller),
                VaultStatus.locked => UnlockPage(controller: _controller),
                VaultStatus.unlocked => VaultShell(
                  controller: _controller,
                  themeController: _themeController,
                ),
              };
            },
          ),
          builder: (context, child) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            isDark
                ? 'assets/images/unlock_background.png'
                : 'assets/images/unlock_background_light.png',
            fit: BoxFit.cover,
          ),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
