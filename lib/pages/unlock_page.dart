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

class _UnlockPageState extends State<UnlockPage> {
  bool _showPassword = false;
  final _passwordController = TextEditingController();

  void _unlock() {
    widget.controller.unlock(_passwordController.text);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
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
          ColoredBox(
            color: isDark ? const Color(0x5500110D) : const Color(0x18FFFFFF),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/keynest_mark.png',
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KeyNest',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '只属于你的密码',
                    style: TextStyle(color: accent, letterSpacing: 4),
                  ),
                  const Spacer(flex: 2),
                  SurfacePanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (widget.controller.biometricConfigured) ...[
                          InkWell(
                            onTap: widget.controller.busy
                                ? null
                                : widget.controller.unlockWithBiometrics,
                            borderRadius: BorderRadius.circular(44),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                size: 52,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('使用生物识别解锁'),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '或输入主密码',
                                    style: TextStyle(
                                      color: context.appTextMuted,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                          ),
                        ],
                        if (widget.controller.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            widget.controller.errorMessage!,
                            style: TextStyle(color: context.appDanger),
                          ),
                        ],
                        if (!widget.controller.biometricConfigured)
                          const SizedBox(height: 4),
                        TextField(
                          controller: _passwordController,
                          maxLength: 256,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: '主密码',
                            counterText: '',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _showPassword ? '隐藏密码' : '显示密码',
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _unlock(),
                        ),
                        const SizedBox(height: 12),
                        if (widget.controller.busy)
                          const SizedBox(
                            height: 46,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          PrimaryButton(
                            label: '解锁',
                            onPressed: _unlock,
                            icon: Icons.arrow_forward_rounded,
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '数据始终存储在本地设备',
                    style: TextStyle(color: context.appTextMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  bool _enableBiometrics = false;
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
      enableBiometrics: _enableBiometrics,
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
          ColoredBox(
            color: isDark ? const Color(0x9900110D) : const Color(0x22FFFFFF),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
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
                    '主密码只用于本地加密，我们无法替你找回。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextMuted),
                  ),
                  const SizedBox(height: 28),
                  SurfacePanel(
                    child: Column(
                      children: [
                        TextField(
                          controller: _password,
                          maxLength: 256,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: '主密码',
                            counterText: '',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _enableBiometrics,
                            onChanged: (value) =>
                                setState(() => _enableBiometrics = value),
                            title: const Text('启用生物识别快捷解锁'),
                            secondary: const Icon(Icons.fingerprint_rounded),
                          ),
                        ],
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            error,
                            style: TextStyle(color: context.appDanger),
                          ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
