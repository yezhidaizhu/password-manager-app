import 'package:flutter/material.dart';

Future<String?> showPasswordResetDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _PasswordResetDialog(),
  );
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog();

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscureText = true;
  String? _error;

  void _submit() {
    if (_password.text.length < 8) {
      setState(() => _error = '主密码至少需要 8 个字符');
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = '两次输入的主密码不一致');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: const Text('设置新主密码'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _password,
              autofocus: true,
              obscureText: _obscureText,
              maxLength: 256,
              decoration: InputDecoration(
                labelText: '新主密码',
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: _obscureText ? '显示密码' : '隐藏密码',
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmation,
              obscureText: _obscureText,
              maxLength: 256,
              decoration: const InputDecoration(
                labelText: '确认新主密码',
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _submit,
                child: const Text('确认修改'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<String?> showBackupPasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _BackupPasswordDialog(),
    );

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog();

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _password = TextEditingController();
  bool _obscured = true;

  void _submit() {
    if (_password.text.isNotEmpty) Navigator.pop(context, _password.text);
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.all(24),
    actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    title: const Text('验证备份'),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _password,
        autofocus: true,
        obscureText: _obscured,
        maxLength: 256,
        decoration: InputDecoration(
          labelText: '备份创建时的主密码',
          counterText: '',
          suffixIcon: IconButton(
            tooltip: _obscured ? '显示密码' : '隐藏密码',
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: _submit, child: const Text('验证')),
          ),
        ],
      ),
    ],
  );
}
