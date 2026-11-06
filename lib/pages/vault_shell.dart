import 'package:flutter/material.dart';

import '../controllers/theme_controller.dart';
import '../controllers/vault_controller.dart';
import '../models/credential.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'credential_pages.dart';
import 'settings_pages.dart';

class VaultShell extends StatefulWidget {
  const VaultShell({
    required this.controller,
    required this.themeController,
    super.key,
  });

  final VaultController controller;
  final ThemeController themeController;

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _index = 0;
  late final List<Widget> _pages = [
    VaultHomePage(controller: widget.controller),
    PasswordGeneratorPage(controller: widget.controller),
    SettingsPage(
      controller: widget.controller,
      themeController: widget.themeController,
    ),
  ];

  void _selectPage(int value) {
    if (value == _index) return;
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _selectPage,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 23,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.key_outlined),
            activeIcon: Icon(Icons.key_rounded),
            label: '账号',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high_outlined),
            activeIcon: Icon(Icons.auto_fix_high_rounded),
            label: '生成',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune_rounded),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class VaultHomePage extends StatefulWidget {
  const VaultHomePage({required this.controller, super.key});

  final VaultController controller;

  @override
  State<VaultHomePage> createState() => _VaultHomePageState();
}

class _VaultHomePageState extends State<VaultHomePage> {
  String _selectedTag = '全部';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller.credentialChanges,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final tags = <String>['全部', ...widget.controller.tags];
    final selectedTag = tags.contains(_selectedTag) ? _selectedTag : '全部';
    final filtered = switch (selectedTag) {
      '全部' => widget.controller.orderedCredentials,
      _ =>
        widget.controller.orderedCredentials
            .where((item) => item.tags.contains(selectedTag))
            .toList(),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'KeyNest',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: '搜索',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SearchPage(controller: widget.controller),
                  ),
                ),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton.filled(
                tooltip: '添加账号',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EditCredentialPage(controller: widget.controller),
                  ),
                ),
                icon: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tags.map((label) {
                final selected = selectedTag == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedTag = label),
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundColor: context.appSurface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : context.appText,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: context.appBorder),
                    showCheckmark: false,
                    visualDensity: const VisualDensity(vertical: -2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                selectedTag == '全部' ? '全部账号' : selectedTag,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${filtered.length}',
                style: TextStyle(color: context.appTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/keynest_mark.png',
                          width: 56,
                          height: 56,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedTag == '全部' ? '还没有账号' : '该标签暂无账号',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '添加第一条记录，数据只保存在本地。',
                          style: TextStyle(color: context.appTextMuted),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => EditCredentialPage(
                                controller: widget.controller,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('添加账号'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 18),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(indent: 56),
                    itemBuilder: (context, index) {
                      final credential = filtered[index];
                      return CredentialTile(
                        credential: credential,
                        onPinned: () async {
                          final saved = await widget.controller.togglePinned(
                            credential.id,
                          );
                          if (!saved && context.mounted) {
                            showAppToast(
                              context,
                              '置顶保存失败，请重试',
                              type: AppToastType.error,
                            );
                          }
                        },
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CredentialDetailPage(
                              controller: widget.controller,
                              credential: credential,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
