import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/vault_controller.dart';
import '../models/credential.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'settings_pages.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({required this.controller, super.key});

  final VaultController controller;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.controller.orderedCredentials.where((item) {
      final query = _query.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.username.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: '搜索账号、网站或备注',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => CredentialTile(
                    credential: results[index],
                    onPinned: () =>
                        widget.controller.togglePinned(results[index].id),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CredentialDetailPage(
                          controller: widget.controller,
                          credential: results[index],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CredentialDetailPage extends StatefulWidget {
  const CredentialDetailPage({
    required this.controller,
    required this.credential,
    super.key,
  });

  final VaultController controller;
  final Credential credential;

  @override
  State<CredentialDetailPage> createState() => _CredentialDetailPageState();
}

class _CredentialDetailPageState extends State<CredentialDetailPage> {
  bool _showPassword = false;

  Credential get _current => widget.controller.credentials.firstWhere(
    (item) => item.id == widget.credential.id,
    orElse: () => widget.credential,
  );

  void _message(String value, {AppToastType type = AppToastType.success}) {
    showAppToast(context, value, type: type);
  }

  Future<void> _copy(String value, String message) async {
    await widget.controller.copyToClipboard(value);
    if (mounted) _message(message);
  }

  Future<void> _openWebsite(String website) async {
    if (website.isEmpty) {
      _message('未填写网站地址', type: AppToastType.info);
      return;
    }
    final normalized = website.contains('://') ? website : 'https://$website';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _message('无法打开网站', type: AppToastType.error);
    }
  }

  Future<void> _delete(Credential item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录？'),
        content: Text('将永久删除 ${item.name}，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: context.appDanger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.deleteCredential(item.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = _current;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              PageHeader(
                title: '',
                onBack: () => Navigator.pop(context),
                trailing: TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => EditCredentialPage(
                          controller: widget.controller,
                          credential: item,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text('编辑'),
                ),
              ),
              BrandAvatar(credential: item, size: 72),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              SurfacePanel(
                child: Column(
                  children: [
                    _DetailRow(
                      label: '用户名',
                      value: item.username,
                      icon: Icons.copy_rounded,
                      onPressed: () => _copy(item.username, '用户名已复制'),
                    ),
                    const Divider(height: 28),
                    _DetailRow(
                      label: '密码',
                      value: _showPassword ? item.password : '••••••••••••',
                      icon: Icons.copy_rounded,
                      onPressed: () => _copy(item.password, '密码已复制，稍后将自动清除'),
                      leadingAction: IconButton(
                        tooltip: _showPassword ? '隐藏密码' : '显示密码',
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    if (item.website.isNotEmpty) ...[
                      const Divider(height: 28),
                      _DetailRow(
                        label: '网站',
                        value: item.website,
                        icon: Icons.open_in_new_rounded,
                        onPressed: () => _openWebsite(item.website),
                      ),
                    ],
                    if (item.note.isNotEmpty) ...[
                      const Divider(height: 28),
                      _DetailRow(label: '备注', value: item.note),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.person_outline,
                      label: '复制账号',
                      onPressed: () => _copy(item.username, '用户名已复制'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: '复制密码',
                      primary: true,
                      onPressed: () => _copy(item.password, '密码已复制，稍后将自动清除'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: '打开网站',
                      onPressed: () => _openWebsite(item.website),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _delete(item),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除记录'),
                style: TextButton.styleFrom(foregroundColor: context.appDanger),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.leadingAction,
    this.onPressed,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? leadingAction;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: context.appTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(value),
            ],
          ),
        ),
        if (leadingAction != null) leadingAction!,
        if (icon != null)
          IconButton(onPressed: onPressed, icon: Icon(icon, size: 20)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.primary : context.appSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary ? AppColors.primary : context.appBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primary ? const Color(0xFF002E21) : context.appText,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: primary ? const Color(0xFF002E21) : context.appText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCredentialPage extends StatefulWidget {
  const EditCredentialPage({
    required this.controller,
    super.key,
    this.credential,
  });

  final VaultController controller;
  final Credential? credential;

  @override
  State<EditCredentialPage> createState() => _EditCredentialPageState();
}

class _EditCredentialPageState extends State<EditCredentialPage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _website;
  late final TextEditingController _note;
  late String _category;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.credential;
    _name = TextEditingController(text: item?.name);
    _username = TextEditingController(text: item?.username);
    _password = TextEditingController(text: item?.password);
    _website = TextEditingController(text: item?.website);
    _note = TextEditingController(text: item?.note);
    _category = item?.category ?? '账号';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _username.text.trim().isEmpty ||
        _password.text.isEmpty) {
      setState(() => _error = '名称、用户名和密码不能为空');
      return;
    }
    final previous = widget.credential;
    final credential = previous == null
        ? Credential(
            name: _name.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            website: _website.text.trim(),
            note: _note.text.trim(),
            category: _category,
          )
        : previous.copyWith(
            name: _name.text.trim(),
            username: _username.text.trim(),
            password: _password.text,
            website: _website.text.trim(),
            note: _note.text.trim(),
            category: _category,
          );
    if (previous == null) {
      await widget.controller.addCredential(credential);
    } else {
      await widget.controller.updateCredential(credential);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _generatePassword() async {
    final generated = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => PasswordGeneratorPage(
          controller: widget.controller,
          standalone: true,
        ),
      ),
    );
    if (generated != null) _password.text = generated;
  }

  Future<void> _manageCategories() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CategoryManagementPage(controller: widget.controller),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (!widget.controller.categories.contains(_category)) {
        _category = '账号';
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _website.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              PageHeader(
                title: widget.credential == null ? '添加记录' : '编辑记录',
                onBack: () => Navigator.pop(context),
                trailing: IconButton.filled(
                  tooltip: '保存',
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 14),
                  children: [
                    _LabeledField(
                      label: '名称',
                      hint: '例如：我的账号',
                      controller: _name,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: '分类',
                          suffixIcon: IconButton(
                            tooltip: '管理分类',
                            onPressed: _manageCategories,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                        items:
                            <String>{...widget.controller.categories, _category}
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => _category = value ?? '账号'),
                      ),
                    ),
                    _LabeledField(
                      label: '用户名',
                      hint: '输入用户名或邮箱',
                      controller: _username,
                    ),
                    _LabeledField(
                      label: '密码',
                      hint: '点击生成安全密码',
                      controller: _password,
                      suffix: IconButton(
                        tooltip: '生成密码',
                        onPressed: _generatePassword,
                        icon: const Icon(
                          Icons.casino_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _LabeledField(
                      label: '网站',
                      hint: 'https://',
                      controller: _website,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          _error!,
                          style: TextStyle(color: context.appDanger),
                        ),
                      ),
                    _LabeledField(
                      label: '备注',
                      hint: '可选',
                      controller: _note,
                      maxLines: 4,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? suffix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: context.appTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      ),
    );
  }
}
