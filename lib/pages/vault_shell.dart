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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _selectPage(int value) {
    if (value == _index) return;
    setState(() => _index = value);
    _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      VaultHomePage(controller: widget.controller),
      PasswordGeneratorPage(controller: widget.controller),
      SettingsPage(
        controller: widget.controller,
        themeController: widget.themeController,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
      ),
      bottomNavigationBar: _VaultNavigationBar(
        selectedIndex: _index,
        onSelected: _selectPage,
      ),
    );
  }
}

class _VaultNavigationBar extends StatelessWidget {
  const _VaultNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items =
      <({IconData icon, IconData selectedIcon, String label})>[
        (
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: '账号',
        ),
        (
          icon: Icons.auto_awesome_outlined,
          selectedIcon: Icons.auto_awesome,
          label: '生成',
        ),
        (
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          label: '设置',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? const [
                    Color(0xCC20DFA1),
                    Color(0x55245246),
                    Color(0xAA20DFA1),
                  ]
                : const [
                    Color(0xCC0B8F68),
                    Color(0xAAC5DCD2),
                    Color(0x99147A5D),
                  ],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0A2D25), Color(0xFF061F1A)]
                  : const [Color(0xFFFFFFFF), Color(0xFFECF5F0)],
            ),
            borderRadius: const BorderRadius.all(Radius.circular(25)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / _items.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubic,
                    left: segmentWidth * selectedIndex + 2,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth - 4,
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(selectedIndex),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 480),
                        curve: const Interval(
                          0.42,
                          1,
                          curve: Curves.easeOutCubic,
                        ),
                        builder: (context, glow, _) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(
                                    0xFF10A879,
                                  ).withValues(alpha: 0.06 * glow),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: 0.08 + 0.06 * glow,
                                ),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 0,
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        stops: const [0, 0.25, 0.5, 0.75, 1],
                                        colors: [
                                          Colors.transparent,
                                          accent.withValues(alpha: 0.4 * glow),
                                          accent.withValues(alpha: glow),
                                          accent.withValues(alpha: 0.4 * glow),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(
                                            alpha: 0.48 * glow,
                                          ),
                                          blurRadius: 8 * glow,
                                          spreadRadius: 0.8 * glow,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  child: Opacity(
                                    opacity: glow,
                                    child: Transform.scale(
                                      scale: 0.6 + 0.4 * glow,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: accent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: 0.55 * glow,
                                              ),
                                              blurRadius: 5 * glow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final selected = selectedIndex == index;
                      return Expanded(
                        child: Semantics(
                          selected: selected,
                          button: true,
                          label: item.label,
                          child: InkWell(
                            onTap: () => onSelected(index),
                            borderRadius: BorderRadius.circular(21),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: selected ? 1 : 0),
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeInOutCubic,
                              builder: (context, progress, _) {
                                final color = Color.lerp(
                                  context.appTextMuted,
                                  accent,
                                  progress,
                                )!;
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.86,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Transform.scale(
                                        key: ValueKey(selected),
                                        scale: 1 + progress * 0.06,
                                        child: Icon(
                                          selected
                                              ? item.selectedIcon
                                              : item.icon,
                                          size: 20,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
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
    final categories = <String>['全部', ...widget.controller.categories];
    final selectedCategory = categories.contains(_category) ? _category : '全部';
    final filtered = switch (selectedCategory) {
      '全部' => widget.controller.orderedCredentials,
      _ =>
        widget.controller.orderedCredentials
            .where((item) => item.category == selectedCategory)
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
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((label) {
                final selected = selectedCategory == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = label),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: context.appSurface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
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
                selectedCategory == '全部' ? '全部账号' : selectedCategory,
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
                          width: 72,
                          height: 72,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          selectedCategory == '全部' ? '还没有账号' : '该分类暂无账号',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '添加第一条记录，数据只保存在本地。',
                          style: TextStyle(color: context.appTextMuted),
                        ),
                        const SizedBox(height: 14),
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
                        onPinned: () =>
                            widget.controller.togglePinned(credential.id),
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
