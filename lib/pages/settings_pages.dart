import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
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
    showAppToast(context, '密码已复制，稍后将自动清除');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
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
                Image.asset(
                  isDark
                      ? 'assets/images/password_cube_cropped.png'
                      : 'assets/images/password_cube_light.png',
                  width: double.infinity,
                  height: 180,
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
                      Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 5,
                              margin: EdgeInsets.only(
                                right: index == 3 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: index < strength.level
                                    ? strengthColors[strength.level - 1]
                                    : context.appBorder,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          strength.label,
                          style: TextStyle(
                            color: strengthColors[strength.level - 1],
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
                              min: 6,
                              max: 24,
                              divisions: 18,
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
                const SizedBox(height: 12),
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
      height: 44,
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

  void _showCategoryManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryManagementPage(controller: controller),
      ),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 12),
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
                const SizedBox(height: 20),
                const _SettingsSectionLabel('账号'),
                const SizedBox(height: 8),
                SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: _SettingsTile(
                    icon: Icons.label_outline_rounded,
                    title: '分类管理',
                    subtitle: '${controller.categories.length} 个分类',
                    onTap: () => _showCategoryManagement(context),
                    showDivider: false,
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: controller.lock,
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('立即锁定'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: context.appBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({required this.controller, super.key});

  final VaultController controller;

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  int _credentialCount(String category) => widget.controller.credentials
      .where((item) => item.category == category)
      .length;

  Future<T?> _showCategoryDialog<T>({required WidgetBuilder builder}) async {
    final route = DialogRoute<T>(context: context, builder: builder);
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    return result;
  }

  Future<void> _editCategory({String? previous}) async {
    final value = await _showCategoryDialog<String>(
      builder: (_) => _CategoryNameDialog(previous: previous),
    );
    if (value == null || !mounted) return;
    final success = previous == null
        ? await widget.controller.addCategory(value)
        : await widget.controller.renameCategory(previous, value);
    if (!mounted) return;
    if (!success) {
      showAppToast(context, '分类名称为空或已存在', type: AppToastType.error);
      return;
    }
    setState(() {});
  }

  Future<void> _deleteCategory(String category) async {
    final count = _credentialCount(category);
    final confirmed = await _showCategoryDialog<bool>(
      builder: (dialogContext) => AlertDialog(
        title: Text('删除“$category”？'),
        content: Text(count == 0 ? '删除后无法撤销。' : '其中的 $count 个账号将移到“账号”分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.appDanger,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await widget.controller.deleteCategory(category);
    if (!mounted) return;
    if (!success) {
      showAppToast(context, '该分类无法删除', type: AppToastType.error);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categories;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              PageHeader(title: '分类管理', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 12),
              Expanded(
                child: SurfacePanel(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 68),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isDefault = category == '账号';
                      final count = _credentialCount(category);
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.label_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          isDefault ? '默认分类 · $count 个账号' : '$count 个账号',
                          style: TextStyle(
                            color: context.appTextMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isDefault
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: '重命名',
                                    onPressed: () =>
                                        _editCategory(previous: category),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '删除',
                                    onPressed: () => _deleteCategory(category),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: context.appDanger,
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: '新建分类',
                icon: Icons.add_rounded,
                onPressed: _editCategory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({this.previous});

  final String? previous;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.previous);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.previous == null ? '新建分类' : '重命名分类'),
      content: TextField(
        controller: _input,
        autofocus: true,
        maxLength: 12,
        decoration: const InputDecoration(hintText: '输入分类名称'),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _input.text),
          child: const Text('保存'),
        ),
      ],
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
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
        if (showDivider) const Divider(height: 1, indent: 68),
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
            SizedBox(
              width: double.infinity,
              height: 44,
              child: SegmentedButton<ThemeMode>(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('系统'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('浅色'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('深色'),
                  ),
                ],
                selected: {controller.mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  controller.setMode(selection.first);
                  Navigator.pop(context);
                },
              ),
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
    final imported = await controller.importBackup();
    if (!context.mounted) return;
    if (!imported && controller.errorMessage != null) {
      _message(context, controller.errorMessage!, type: AppToastType.error);
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
            style: FilledButton.styleFrom(backgroundColor: context.appDanger),
            child: const Text('永久删除'),
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
                  padding: const EdgeInsets.only(top: 12),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 24),
                    _SettingsSectionLabel('危险操作'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.appDanger.withValues(alpha: 0.06),
                        border: Border.all(
                          color: context.appDanger.withValues(alpha: 0.38),
                        ),
                        borderRadius: BorderRadius.circular(18),
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(Icons.storage_rounded, color: accent, size: 32),
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
