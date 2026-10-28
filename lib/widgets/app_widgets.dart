import 'package:flutter/material.dart';

import '../models/credential.dart';
import '../theme/app_theme.dart';

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
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
        color: color ?? AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
    this.onFavorite,
  });

  final Credential credential;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              BrandAvatar(credential: credential, size: 42),
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
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onFavorite != null)
                IconButton(
                  tooltip: credential.favorite ? '取消收藏' : '收藏',
                  onPressed: onFavorite,
                  icon: Icon(
                    credential.favorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: credential.favorite
                        ? AppColors.warning
                        : AppColors.textMuted,
                    size: 20,
                  ),
                )
              else if (credential.favorite)
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
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
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF002E21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      height: 56,
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
