import 'package:flutter/material.dart';

import '../controllers/vault_controller.dart';
import '../models/credential.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'credential_pages.dart';
import 'settings_pages.dart';

class VaultShell extends StatefulWidget {
  const VaultShell({required this.controller, super.key});

  final VaultController controller;

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      VaultHomePage(controller: widget.controller),
      PasswordGeneratorPage(controller: widget.controller),
      LocalSecurityPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: const Color(0xFF061F19),
        indicatorColor: AppColors.primary.withValues(alpha: 0.22),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '账号',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '生成',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: '安全',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
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
  String _category = '全部';

  @override
  Widget build(BuildContext context) {
    final filtered = switch (_category) {
      '全部' => widget.controller.credentials,
      '收藏' =>
        widget.controller.credentials.where((item) => item.favorite).toList(),
      _ =>
        widget.controller.credentials
            .where((item) => item.category == _category)
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
                  'MAOBAO',
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
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['全部', '收藏', '常用', '工作', '生活', '银行'].map((label) {
                final selected = _category == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = label),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color(0xFF002E21)
                          : AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('全部账号', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${filtered.length}',
                style: const TextStyle(color: AppColors.textMuted),
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
                          'assets/images/maobao_mark.png',
                          width: 72,
                          height: 72,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _category == '全部' ? '还没有账号' : '该分类暂无账号',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '添加第一条记录，数据只保存在本地。',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 18),
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
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final credential = filtered[index];
                      return CredentialTile(
                        credential: credential,
                        onFavorite: () =>
                            widget.controller.toggleFavorite(credential.id),
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
