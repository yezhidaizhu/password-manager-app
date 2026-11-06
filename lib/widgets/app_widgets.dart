import 'dart:async';

import 'package:flutter/material.dart';

import '../models/credential.dart';
import '../theme/app_theme.dart';

enum AppToastType { success, info, error }

OverlayEntry? _activeToastEntry;

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
}) {
  _activeToastEntry?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      message: message,
      type: type,
      onDismissed: () {
        if (_activeToastEntry == entry) _activeToastEntry = null;
        entry.remove();
      },
    ),
  );
  _activeToastEntry = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _TopToast extends StatefulWidget {
  const _TopToast({
    required this.message,
    required this.type,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _dismissing = false;

  Color _accent(BuildContext context) => switch (widget.type) {
    AppToastType.success => Theme.of(context).colorScheme.primary,
    AppToastType.info => context.appInfo,
    AppToastType.error => context.appDanger,
  };

  IconData get _icon => switch (widget.type) {
    AppToastType.success => Icons.check_rounded,
    AppToastType.info => Icons.info_outline_rounded,
    AppToastType.error => Icons.error_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.32),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _timer = Timer(const Duration(seconds: 2), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Positioned(
      top: MediaQuery.viewPaddingOf(context).top + 12,
      left: 24,
      right: 24,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _opacity,
              child: Semantics(
                liveRegion: true,
                label: widget.message,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon, color: accent, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? AppGradients.surface(context) : null,
        border: Border.all(color: context.appBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class BrandAvatar extends StatelessWidget {
  const BrandAvatar({required this.credential, super.key, this.size = 48});

  final Credential credential;
  final double size;

  static const _palette = <Color>[
    Color(0xFF2563EB),
    Color(0xFFC2414A),
    Color(0xFF6D4CCF),
    Color(0xFFA84F00),
    Color(0xFF0F766E),
    Color(0xFFB83280),
    Color(0xFF4F46E5),
    Color(0xFF475569),
  ];

  Color _stableColor(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (credential.logoAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.asset(
          credential.logoAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _stableColor('${credential.name}:${credential.username}'),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        _initial(credential.name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CredentialTile extends StatelessWidget {
  const CredentialTile({
    required this.credential,
    required this.onTap,
    super.key,
    this.onPinned,
  });

  final Credential credential;
  final VoidCallback onTap;
  final VoidCallback? onPinned;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              BrandAvatar(credential: credential, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      credential.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onPinned != null)
                IconButton(
                  tooltip: credential.pinned ? '取消置顶' : '置顶',
                  onPressed: onPinned,
                  icon: Icon(
                    credential.pinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: credential.pinned
                        ? Theme.of(context).colorScheme.primary
                        : context.appTextMuted,
                    size: 20,
                  ),
                )
              else if (credential.pinned)
                Icon(
                  Icons.push_pin_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              Icon(Icons.chevron_right_rounded, color: context.appTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    super.key,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: '返回',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}
