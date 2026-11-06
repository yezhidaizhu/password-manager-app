import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../controllers/vault_controller.dart';
import '../services/password_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/password_reset_dialog.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({
    required this.controller,
    super.key,
    this.standalone = false,
  });

  final VaultController controller;
  final bool standalone;

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  double _length = 16;
  bool _upper = true;
  bool _lower = true;
  bool _numbers = true;
  bool _symbols = true;
  final PasswordGenerator _generator = PasswordGenerator();
  Timer? _lengthDebounce;
  late String _password;

  @override
  void initState() {
    super.initState();
    _password = _createPassword();
  }

  String _createPassword() {
    return _generator.generate(
      length: _length.round(),
      upper: _upper,
      lower: _lower,
      numbers: _numbers,
      symbols: _symbols,
    );
  }

  void _update(VoidCallback change) {
    _lengthDebounce?.cancel();
    setState(() {
      change();
      if (!_upper && !_lower && !_numbers && !_symbols) _lower = true;
      _password = _createPassword();
    });
  }

  void _updateLength(double value) {
    setState(() => _length = value);
    _lengthDebounce?.cancel();
    _lengthDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _password = _createPassword());
    });
  }

  void _commitLength() {
    _lengthDebounce?.cancel();
    setState(() => _password = _createPassword());
  }

  @override
  void dispose() {
    _lengthDebounce?.cancel();
    super.dispose();
  }

  Future<void> _copyPassword() async {
    await widget.controller.copyToClipboard(_password);
    if (!mounted) return;
    showAppToast(context, '密码已复制，稍后将自动清除');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strength = _generator.strengthOf(_password);
    final strengthColors = isDark
        ? const [
            Color(0xFFFF6B70),
            Color(0xFFFF9F43),
            Color(0xFFFFCE55),
            Color(0xFF20DFA1),
          ]
        : const [
            Color(0xFFB3261E),
            Color(0xFFC45A00),
            Color(0xFF9A6400),
            Color(0xFF0B8F68),
          ];
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        children: [
          PageHeader(
            title: '生成密码',
            onBack: widget.standalone ? () => Navigator.pop(context) : null,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 14, 0, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _password,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyPassword,
                            tooltip: '复制密码',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.copy_outlined, size: 21),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: List.generate(
                                4,
                                (index) => Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    height: 3,
                                    margin: EdgeInsets.only(
                                      right: index == 3 ? 0 : 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index < strength.level
                                          ? strengthColors[strength.level - 1]
                                          : context.appBorder,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            strength.label,
                            style: TextStyle(
                              color: strengthColors[strength.level - 1],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: context.appBorder),
                const SizedBox(height: 10),
                SurfacePanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('长度'),
                          Expanded(
                            child: Slider(
                              value: _length,
                              min: 6,
                              max: 24,
                              onChanged: _updateLength,
                              onChangeEnd: (_) => _commitLength(),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text('${_length.round()}'),
                          ),
                        ],
                      ),
                      _SwitchRow(
                        label: '包含大写字母 (A–Z)',
                        value: _upper,
                        onChanged: (v) => _update(() => _upper = v),
                      ),
                      _SwitchRow(
                        label: '包含小写字母 (a–z)',
                        value: _lower,
                        onChanged: (v) => _update(() => _lower = v),
                      ),
                      _SwitchRow(
                        label: '包含数字 (0–9)',
                        value: _numbers,
                        onChanged: (v) => _update(() => _numbers = v),
                      ),
                      _SwitchRow(
                        label: '包含特殊字符 (!@#…)',
                        value: _symbols,
                        onChanged: (v) => _update(() => _symbols = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: widget.standalone ? '使用此密码' : '生成新密码',
                  onPressed: widget.standalone
                      ? () => Navigator.pop(context, _password)
                      : () => _update(() {}),
                  icon: widget.standalone
                      ? Icons.check_rounded
                      : Icons.refresh_rounded,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.standalone) return content;
    return Scaffold(body: SafeArea(child: content));
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Transform.scale(
              scale: 0.88,
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    required this.themeController,
    super.key,
  });

  final VaultController controller;
  final ThemeController themeController;

  Future<void> _showSecuritySettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appSurface,
      builder: (_) => _SecuritySettingsSheet(controller: controller),
    );
  }

  Future<void> _showThemeSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      builder: (_) => _ThemeModeSheet(controller: themeController),
    );
  }

  void _showDataManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DataManagementPage(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controller, themeController]),
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: '设置'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 6),
              children: [
                const _SettingsSectionLabel('安全与数据'),
                const SizedBox(height: 8),
                SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.fingerprint_rounded,
                        title: '安全与解锁',
                        subtitle: controller.biometricConfigured
                            ? '生物识别已启用'
                            : '主密码、自动锁定与剪贴板保护',
                        onTap: () => _showSecuritySettings(context),
                      ),
                      _SettingsTile(
                        icon: Icons.storage_rounded,
                        title: '数据管理',
                        subtitle: '本地加密存储、备份与恢复',
                        onTap: () => _showDataManagement(context),
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _SettingsSectionLabel('个性化'),
                const SizedBox(height: 8),
                SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: '外观',
                    subtitle: themeController.label,
                    onTap: () => _showThemeSettings(context),
                    showDivider: false,
                  ),
                ),
                const SizedBox(height: 14),
                const _SettingsSectionLabel('其他'),
                const SizedBox(height: 8),
                SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: '关于 KeyNest',
                    subtitle: '版本 1.0.0',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'KeyNest',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '本地优先的加密密码保险库',
                    ),
                    showDivider: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.appTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: context.appTextMuted, fontSize: 12),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: context.appTextMuted,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 60),
      ],
    );
  }
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('外观', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final option in const [
              (ThemeMode.system, '跟随系统'),
              (ThemeMode.light, '浅色'),
              (ThemeMode.dark, '深色'),
            ])
              RadioListTile<ThemeMode>(
                value: option.$1,
                groupValue: controller.mode,
                title: Text(option.$2),
                contentPadding: EdgeInsets.zero,
                onChanged: (mode) {
                  if (mode == null) return;
                  controller.setMode(mode);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SecuritySettingsSheet extends StatefulWidget {
  const _SecuritySettingsSheet({required this.controller});

  final VaultController controller;

  @override
  State<_SecuritySettingsSheet> createState() => _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState extends State<_SecuritySettingsSheet> {
  Future<void> _toggleBiometrics(bool value) async {
    final success = await widget.controller.setBiometricEnabled(value);
    if (!mounted) return;
    if (!success) {
      showAppToast(
        context,
        widget.controller.errorMessage ?? '无法启用生物识别',
        type: AppToastType.error,
      );
    }
    setState(() {});
  }

  Future<void> _resetPassword() async {
    final authenticated = await widget.controller.beginPasswordReset();
    if (!mounted) return;
    if (!authenticated) {
      showAppToast(
        context,
        widget.controller.errorMessage ?? '无法验证手机身份',
        type: AppToastType.error,
      );
      return;
    }
    final password = await showPasswordResetDialog(context);
    if (password == null) {
      widget.controller.cancelPasswordReset();
      return;
    }
    final changed = await widget.controller.resetPassword(password);
    if (!mounted) return;
    showAppToast(
      context,
      changed ? '主密码已修改' : widget.controller.errorMessage ?? '修改失败',
      type: changed ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('安全设置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.controller.biometricConfigured,
              onChanged: widget.controller.biometricAvailable
                  ? _toggleBiometrics
                  : null,
              title: const Text('生物识别快捷解锁'),
              subtitle: Text(
                widget.controller.biometricAvailable ? '使用设备生物识别验证' : '当前设备不可用',
              ),
              secondary: const Icon(Icons.fingerprint_rounded),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_rounded),
              title: const Text('修改主密码'),
              subtitle: const Text('使用手机锁屏验证身份'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.controller.passwordResetAvailable
                  ? _resetPassword
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.lock_outline_rounded),
              title: const Text('后台自动锁定'),
              subtitle: const Text('切到后台立即锁定'),
              value: settings.backgroundAutoLock,
              onChanged: (value) async {
                await widget.controller.updateSecuritySettings(
                  backgroundAutoLock: value,
                );
                if (mounted) setState(() {});
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.privacy_tip_outlined),
              title: const Text('隐私保护'),
              subtitle: const Text('隐藏后台预览，同时禁止截图'),
              value: settings.privacyProtection,
              onChanged: (value) async {
                await widget.controller.updateSecuritySettings(
                  privacyProtection: value,
                );
                if (mounted) setState(() {});
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.content_paste_off_outlined),
              title: const Text('剪贴板自动清除'),
              trailing: DropdownButton<int>(
                value: settings.clipboardSeconds,
                items: const [15, 30, 60, 120]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value 秒'),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  await widget.controller.updateSecuritySettings(
                    clipboardSeconds: value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({required this.controller, super.key});

  final VaultController controller;

  void _message(
    BuildContext context,
    String text, {
    AppToastType type = AppToastType.success,
  }) {
    showAppToast(context, text, type: type);
  }

  Future<void> _export(BuildContext context) async {
    final exported = await controller.exportBackup();
    if (!context.mounted) return;
    if (exported) _message(context, '加密备份已导出');
    if (!exported && controller.errorMessage != null) {
      _message(context, controller.errorMessage!, type: AppToastType.error);
    }
  }

  Future<void> _import(BuildContext context) async {
    if (controller.busy) return;
    final envelope = await controller.pickBackup();
    if (!context.mounted) return;
    if (envelope == null) {
      if (controller.errorMessage != null) {
        _message(context, controller.errorMessage!, type: AppToastType.error);
      }
      return;
    }
    if (!await controller.waitForUnlock() || !context.mounted) return;
    final password = await showBackupPasswordDialog(context);
    if (password == null || !context.mounted) return;
    final data = await controller.validateBackup(envelope, password);
    if (!context.mounted) return;
    if (data == null) {
      _message(
        context,
        controller.errorMessage ?? '备份验证失败',
        type: AppToastType.error,
      );
      return;
    }
    if (!await controller.waitForUnlock() || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: const Text('替换当前保险库？'),
        content: SizedBox(
          width: 360,
          child: Text(
            '备份验证通过，共 ${data.credentials.length} 条记录。恢复将替换当前全部记录和设置，当前主密码保持不变。',
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确认恢复'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (!await controller.waitForUnlock() || !context.mounted) return;
    final imported = await controller.importBackup(data);
    if (!context.mounted) return;
    _message(
      context,
      imported ? '备份已恢复' : controller.errorMessage ?? '恢复失败',
      type: imported ? AppToastType.success : AppToastType.error,
    );
    if (imported) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: const Text('清空保险库？'),
        content: SizedBox(
          width: 360,
          child: const Text('设备上的所有账号记录和设置都会永久删除。请先确认已有可用备份。'),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appDanger,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('永久删除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearVault();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: '数据管理', onBack: () => Navigator.pop(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    SurfacePanel(
                      child: Row(
                        children: [
                          const _SecurityIcon(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '本地加密存储',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '数据不上传、不同步，仅保存在当前设备。',
                                  style: TextStyle(
                                    color: context.appTextMuted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SettingsSectionLabel('备份与恢复'),
                    const SizedBox(height: 8),
                    SurfacePanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SecurityTile(
                            icon: Icons.backup_outlined,
                            title: '创建加密备份',
                            subtitle: '导出可离线保存的备份文件',
                            onTap: () => _export(context),
                          ),
                          _SecurityTile(
                            icon: Icons.restore_rounded,
                            title: '从备份恢复',
                            subtitle: '选择本地备份文件并验证',
                            divider: false,
                            onTap: () => _import(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: context.appTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '备份文件使用主密码加密',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SettingsSectionLabel('危险操作'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.appDanger.withValues(alpha: 0.06),
                        border: Border.all(
                          color: context.appDanger.withValues(alpha: 0.38),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _SecurityTile(
                        icon: Icons.delete_forever_outlined,
                        title: '清空所有数据',
                        subtitle: '永久删除当前设备上的账号和设置',
                        danger: true,
                        divider: false,
                        onTap: () => _clear(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityIcon extends StatelessWidget {
  const _SecurityIcon();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.storage_rounded, color: accent, size: 28),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.divider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.appDanger : context.appText;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: context.appTextMuted, fontSize: 12),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: context.appTextMuted,
          ),
          onTap: onTap,
        ),
        if (divider) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
