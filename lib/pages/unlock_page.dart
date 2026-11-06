import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/vault_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class UnlockPage extends StatefulWidget {
  const UnlockPage({required this.controller, super.key});

  final VaultController controller;

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> with WidgetsBindingObserver {
  final _passwordController = TextEditingController();
  bool _deviceAuthenticationPrompted = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _promptDeviceAuthentication();
    });
  }

  void _unlockWithPassword() {
    widget.controller.unlock(_passwordController.text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptDeviceAuthentication();
      });
    }
  }

  void _promptDeviceAuthentication() {
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        _deviceAuthenticationPrompted ||
        !widget.controller.deviceAuthenticationAvailable ||
        !widget.controller.passwordResetAvailable) {
      return;
    }
    _deviceAuthenticationPrompted = true;
    widget.controller.unlockWithDeviceAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final canUnlock =
        widget.controller.deviceAuthenticationAvailable &&
        widget.controller.passwordResetAvailable;
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/keynest_mark.png',
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KeyNest',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  if (kIsWeb) ...[
                    TextField(
                      controller: _passwordController,
                      autofocus: true,
                      maxLength: 256,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: '主密码',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _showPassword ? '隐藏密码' : '显示密码',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _unlockWithPassword(),
                    ),
                    const SizedBox(height: 14),
                    if (!widget.controller.busy)
                      PrimaryButton(
                        label: '解锁',
                        onPressed: _unlockWithPassword,
                        icon: Icons.arrow_forward_rounded,
                      ),
                  ] else ...[
                    IconButton(
                      tooltip: '手机解锁',
                      onPressed: !canUnlock || widget.controller.busy
                          ? null
                          : widget.controller.unlockWithDeviceAuthentication,
                      icon: const Icon(Icons.fingerprint_rounded, size: 44),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(76, 76),
                        foregroundColor: accent,
                        disabledForegroundColor: accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(canUnlock ? '手机解锁' : '手机解锁不可用'),
                  ],
                  if (widget.controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appDanger),
                    ),
                  ],
                  if (widget.controller.busy) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({required this.controller, super.key});

  final VaultController controller;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _showPassword = false;
  String? _validationError;

  Future<void> _create() async {
    final password = _password.text;
    if (password.length < 10) {
      setState(() => _validationError = '主密码至少需要 10 个字符');
      return;
    }
    if (password != _confirmation.text) {
      setState(() => _validationError = '两次输入的主密码不一致');
      return;
    }
    setState(() => _validationError = null);
    await widget.controller.createVault(
      password,
      enableBiometrics: widget.controller.biometricAvailable,
    );
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _validationError ?? widget.controller.errorMessage;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
          child: Column(
            children: [
              Image.asset(
                'assets/images/keynest_mark.png',
                width: 78,
                height: 78,
              ),
              const SizedBox(height: 14),
              Text(
                '创建本地保险库',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.controller.deviceAuthenticationAvailable
                    ? '主密码用于本地加密，忘记后可通过手机身份验证重设。'
                    : '主密码用于本地加密，请妥善保管。',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _password,
                maxLength: 256,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: '主密码',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmation,
                maxLength: 256,
                obscureText: !_showPassword,
                decoration: const InputDecoration(
                  labelText: '确认主密码',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              if (widget.controller.biometricAvailable) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      size: 20,
                      color: context.appTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '将默认启用生物识别解锁',
                      style: TextStyle(color: context.appTextMuted),
                    ),
                  ],
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error, style: TextStyle(color: context.appDanger)),
              ],
              const SizedBox(height: 18),
              if (widget.controller.busy)
                const SizedBox(
                  height: 46,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                PrimaryButton(
                  label: '创建保险库',
                  onPressed: _create,
                  icon: Icons.arrow_forward_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
