import 'package:flutter/foundation.dart';
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _privacyCovered = ValueNotifier<bool>(false);
  static const _privacyChannel = MethodChannel('keynest/privacy');
  bool? _appliedPrivacyProtection = true;
  Route<void>? _lockRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_syncPrivacyProtection);
    _controller.statusChanges.addListener(_dismissLockCover);
    _controller.initialize();
    _themeController.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _privacyCovered.value =
        _controller.settings.privacyProtection &&
        state != AppLifecycleState.resumed;
    if (_controller.status != VaultStatus.unlocked ||
        !_controller.settings.backgroundAutoLock) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      FocusManager.instance.primaryFocus?.unfocus();
      final route = PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/session-lock'),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => PopScope(
          canPop: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => UnlockPage(controller: _controller),
          ),
        ),
      );
      _lockRoute = route;
      _controller.lock(preserveView: true);
      _navigatorKey.currentState!.push(route);
    }
  }

  void _dismissLockCover() {
    final route = _lockRoute;
    if (route == null || _controller.status == VaultStatus.locked) return;
    _lockRoute = null;
    _navigatorKey.currentState?.removeRoute(route);
  }

  Future<void> _syncPrivacyProtection() async {
    final enabled = _controller.settings.privacyProtection;
    _privacyCovered.value =
        enabled &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        enabled == _appliedPrivacyProtection) {
      return;
    }
    _appliedPrivacyProtection = enabled;
    try {
      await _privacyChannel.invokeMethod<void>('setPrivacyProtection', enabled);
    } on MissingPluginException catch (error) {
      _appliedPrivacyProtection = null;
      debugPrint('Privacy protection requires the updated Android app: $error');
    } on PlatformException catch (error) {
      _appliedPrivacyProtection = null;
      debugPrint('Unable to update privacy protection: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_syncPrivacyProtection);
    _controller.statusChanges.removeListener(_dismissLockCover);
    _controller.dispose();
    _themeController.dispose();
    _privacyCovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'KeyNest',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.mode,
          home: AnimatedBuilder(
            animation: _controller.statusChanges,
            builder: (context, _) {
              if (_lockRoute != null ||
                  _controller.status == VaultStatus.unlocked) {
                return VaultShell(
                  controller: _controller,
                  themeController: _themeController,
                );
              }
              return switch (_controller.status) {
                VaultStatus.loading => const _LoadingPage(),
                VaultStatus.needsSetup => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => SetupPage(controller: _controller),
                ),
                VaultStatus.locked => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => UnlockPage(controller: _controller),
                ),
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _privacyCovered,
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
                builder: (context, covered, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    child!,
                    if (covered)
                      Positioned.fill(
                        child: ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: const Center(
                            child: Icon(Icons.lock_outline_rounded, size: 32),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatefulWidget {
  const _LoadingPage();

  @override
  State<_LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<_LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.97,
    end: 1,
  ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeInOut));
  late final Animation<double> _wordmarkOpacity = Tween<double>(
    begin: 0.55,
    end: 1,
  ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeInOut));

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.background
          : AppLightColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ScaleTransition(
              scale: _logoScale,
              child: Image.asset(
                'assets/images/keynest_mark.png',
                width: 61.44,
                height: 61.44,
              ),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, 50.72),
              child: FadeTransition(
                opacity: _wordmarkOpacity,
                child: Text(
                  'KeyNest',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(letterSpacing: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
