import 'package:flutter/material.dart';

import '../controllers/vault_controller.dart';
import '../services/password_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

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
    setState(() {
      change();
      if (!_upper && !_lower && !_numbers && !_symbols) _lower = true;
      _password = _createPassword();
    });
  }

  Future<void> _copyPassword() async {
    await widget.controller.copyToClipboard(_password);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('密码已复制，稍后将自动清除')));
  }

  @override
  Widget build(BuildContext context) {
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
                Image.asset(
                  'assets/images/password_cube_cropped.png',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                SurfacePanel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _password,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyPassword,
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(
                        value: 0.86,
                        color: AppColors.primary,
                        backgroundColor: AppColors.border,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '很强',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SurfacePanel(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('长度'),
                          Expanded(
                            child: Slider(
                              value: _length,
                              min: 8,
                              max: 32,
                              divisions: 24,
                              onChanged: (value) =>
                                  _update(() => _length = value),
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
                const SizedBox(height: 16),
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
    return SizedBox(
      height: 47,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final VaultController controller;

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showSecuritySettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _SecuritySettingsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: '设置'),
          const SizedBox(height: 12),
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  title: '解锁方式',
                  subtitle: controller.biometricConfigured ? '生物识别已启用' : '主密码',
                  onTap: () => _showSecuritySettings(context),
                ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: '本地安全',
                  subtitle: '加密、备份与数据管理',
                  onTap: () => _showSecuritySettings(context),
                ),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: '外观',
                  subtitle: '深色主题',
                  onTap: () => _message(context, '当前设计使用深色主题'),
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '关于 MAOBAO',
                  subtitle: '版本 1.0.0',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'MAOBAO',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '本地优先的加密密码保险库',
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('账号图标', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            '已配置官方图片时显示官方图标；未配置时使用账号名称首字母，并根据账号信息生成稳定底色。',
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.lock,
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('立即锁定'),
            ),
          ),
        ],
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
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 68),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage ?? '无法启用生物识别')),
      );
    }
    setState(() {});
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
                  color: AppColors.border,
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
              leading: const Icon(Icons.timer_outlined),
              title: const Text('自动锁定'),
              trailing: DropdownButton<int>(
                value: settings.autoLockMinutes,
                items: const [1, 5, 15, 30]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value 分钟'),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  await widget.controller.updateSecuritySettings(
                    autoLockMinutes: value,
                  );
                  if (mounted) setState(() {});
                },
              ),
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

class LocalSecurityPage extends StatelessWidget {
  const LocalSecurityPage({required this.controller, super.key});

  final VaultController controller;

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export(BuildContext context) async {
    final exported = await controller.exportBackup();
    if (!context.mounted) return;
    if (exported) _message(context, '加密备份已导出');
    if (!exported && controller.errorMessage != null) {
      _message(context, controller.errorMessage!);
    }
  }

  Future<void> _import(BuildContext context) async {
    final imported = await controller.importBackup();
    if (!context.mounted) return;
    if (!imported && controller.errorMessage != null) {
      _message(context, controller.errorMessage!);
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空保险库？'),
        content: const Text('设备上的所有账号记录和设置都会永久删除。请先确认已有可用备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clearVault();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        children: [
          const PageHeader(title: '本地安全'),
          const SizedBox(height: 12),
          const SurfacePanel(
            child: Row(
              children: [
                _SecurityIcon(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '数据始终存储在本地',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '不上传、不同步，只属于你。',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfacePanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SecurityTile(
                  icon: Icons.backup_outlined,
                  title: '创建本地备份',
                  subtitle: '导出加密备份文件',
                  onTap: () => _export(context),
                ),
                _SecurityTile(
                  icon: Icons.restore_rounded,
                  title: '从备份恢复',
                  subtitle: '选择本地备份文件',
                  onTap: () => _import(context),
                ),
                _SecurityTile(
                  icon: Icons.delete_forever_outlined,
                  title: '清空所有数据',
                  subtitle: '将删除设备上的所有记录',
                  danger: true,
                  divider: false,
                  onTap: () => _clear(context),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            '备份文件同样使用主密码加密',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SecurityIcon extends StatelessWidget {
  const _SecurityIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.storage_rounded,
        color: AppColors.primary,
        size: 32,
      ),
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
    final color = danger ? AppColors.danger : AppColors.text;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
          onTap: onTap,
        ),
        if (divider) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
