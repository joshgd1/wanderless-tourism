import 'package:flutter/material.dart';

/// Wanderless Design System — Linear/Vercel-inspired premium SaaS aesthetic
/// Built for mobile-first, scales gracefully to desktop.
/// Keep theme color: Color(0xFFED8A19) (warm orange)

class AppColors {
  // Brand
  static const brand = Color(0xFFED8A19);
  static const brandLight = Color(0xFFF5A84D);
  static const brandDark = Color(0xFFD47510);

  // Surfaces (Light mode — clean white/gray, minimal)
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFF4F4F5);
  static const surfaceSecondary = Color(0xFFF4F4F7);

  // Borders — subtle, not zero
  static const border = Color(0xFFE4E4E7);
  static const borderStrong = Color(0xFFD4D4D8);

  // Text — high contrast, characterful
  static const textPrimary = Color(0xFF09090B);
  static const textSecondary = Color(0xFF71717A);
  static const textTertiary = Color(0xFFA1A1AA);
  static const textInverse = Color(0xFFFFFFFF);

  // Semantic
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFF7ED);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFEFF6FF);

  // Guide status colors
  static const statusRequested = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF10B981);
  static const statusPaid = Color(0xFF3B82F6);
  static const statusInProgress = Color(0xFF8B5CF6);
  static const statusCompleted = Color(0xFF10B981);
  static const statusCancelled = Color(0xFFEF4444);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
}

/// Typography — Space Grotesk for headings, Inter for body
class AppText {
  // Display
  static const display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Headings
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Labels
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static const labelBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Caption / meta
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );
  static const captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Button
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01,
    height: 1,
  );
}

/// Primary Button — clean, minimal, no heavy shadows
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: widget.width,
          height: 44,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.textTertiary
                : _isPressed
                    ? AppColors.brandDark
                    : _isHovered
                        ? AppColors.brandLight
                        : AppColors.brand,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(widget.label, style: AppText.button.copyWith(color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary / Outline Button
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.brand;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 44,
        decoration: BoxDecoration(
          color: _isHovered ? color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: widget.onPressed == null ? AppColors.border : color,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: widget.onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: color),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppText.button.copyWith(
                      color: widget.onPressed == null ? AppColors.textTertiary : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ghost / Text Button
class GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: widget.onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15, color: color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: AppText.button.copyWith(
                      color: widget.onPressed == null ? AppColors.textTertiary : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Input Field — clean, minimal, with subtle focus ring
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final int maxLines;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.label),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          focusNode: focusNode,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.surfaceSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card — minimal, no heavy elevation, subtle border
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Status Badge — minimal pill
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppText.captionBold.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Shared booking status helpers — used across guide, business, and tourist screens.
class BookingStatus {
  static Color color(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED': return AppColors.warning;
      case 'CONFIRMED': return AppColors.statusConfirmed;
      case 'PAID': return AppColors.statusPaid;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return AppColors.error;
      default: return AppColors.textTertiary;
    }
  }

  static String label(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED': return 'New Request';
      case 'CONFIRMED': return 'Confirmed';
      case 'PAID': return 'Paid';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }
}

/// Avatar — circular with optional border
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.surfaceSecondary,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Divider — subtle, minimal
class AppDivider extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const AppDivider({super.key, this.height, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 1,
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: AppColors.border,
    );
  }
}

/// Bottom Nav Bar item
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
}

/// Bottom Navigation Bar — minimal, pill-style
class AppBottomNav extends StatelessWidget {
  final List<BottomNavItem> items;

  const AppBottomNav({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.map((item) {
              final isSelected = item.isSelected;
              return Expanded(
                child: InkWell(
                  onTap: item.onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                        size: 22,
                        color: isSelected ? AppColors.brand : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          color: isSelected ? AppColors.brand : AppColors.textTertiary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Empty State — clean, centered
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 26, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.h3.copyWith(color: AppColors.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppText.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading indicator — minimal
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppText.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Country flag helper for smart nationality detection
class CountryFlags {
  /// Get country flag emoji from a name, location, or country hint
  static String fromName(String name) {
    final lower = name.toLowerCase();

    // Balinese/Indonesian name patterns
    if (_isBalineseName(lower)) return '🇮🇩';

    // Thai name patterns
    if (_isThaiName(lower)) return '🇹🇭';

    // Vietnamese name patterns
    if (_isVietnameseName(lower)) return '🇻🇳';

    // Filipino name patterns
    if (_isFilipinoName(lower)) return '🇵🇭';

    // Malay name patterns
    if (_isMalayName(lower)) return '🇲🇾';

    // Myanmar name patterns
    if (_isMyanmarName(lower)) return '🇲🇲';

    // Chinese name patterns
    if (_isChineseName(lower)) return '🇨🇳';

    // Korean name patterns
    if (_isKoreanName(lower)) return '🇰🇷';

    // Japanese name patterns
    if (_isJapaneseName(lower)) return '🇯🇵';

    // Indian name patterns
    if (_isIndianName(lower)) return '🇮🇳';

    // Western/European names
    if (_isWesternName(lower, name)) return '🇬🇧';

    // Default to globe
    return '🌏';
  }

  /// Get country flag from location string (e.g., "Bangkok", "Bali")
  static String fromLocation(String location) {
    final lower = location.toLowerCase();

    // Indonesia
    if (lower.contains('bali') || lower.contains('jakarta') ||
        lower.contains('yogyakarta') || lower.contains('surabaya') ||
        lower.contains('nusapenida') || lower.contains('ubud')) {
      return '🇮🇩';
    }

    // Thailand
    if (lower.contains('bangkok') || lower.contains('chiang mai') ||
        lower.contains('phuket') || lower.contains('samui') ||
        lower.contains('pattaya') || lower.contains('krabi')) {
      return '🇹🇭';
    }

    // Vietnam
    if (lower.contains('hanoi') || lower.contains('ho chi minh') ||
        lower.contains('danang') || lower.contains('hoi an')) {
      return '🇻🇳';
    }

    // Philippines
    if (lower.contains('cebu') || lower.contains('boracay') ||
        lower.contains('palawan') || lower.contains('manila')) {
      return '🇵🇭';
    }

    // Malaysia
    if (lower.contains('kuala lumpur') || lower.contains('penang') ||
        lower.contains('langkawi') || lower.contains('malacca')) {
      return '🇲🇾';
    }

    // Singapore
    if (lower.contains('singapore') || lower.contains('sentosa')) {
      return '🇸🇬';
    }

    // Myanmar
    if (lower.contains('yangon') || lower.contains('bagan') ||
        lower.contains('mandalay')) {
      return '🇲🇲';
    }

    // Laos
    if (lower.contains('vientiane') || lower.contains('luang prabang')) {
      return '🇱🇦';
    }

    // Cambodia
    if (lower.contains('siem reap') || lower.contains('phnom penh')) {
      return '🇰🇭';
    }

    // Japan
    if (lower.contains('tokyo') || lower.contains('osaka') ||
        lower.contains('kyoto') || lower.contains('bali')) {
      return '🇯🇵';
    }

    return '🌏';
  }

  /// Get country flag from first name only (for tourists)
  static String fromFirstName(String firstName) {
    final lower = firstName.toLowerCase();

    // Common first names by nationality
    final americanBritish = [
      'sarah', 'michael', 'james', 'emma', 'david', 'lisa', 'john',
      'jennifer', 'william', 'elizabeth', 'richard', 'jessica', 'tom',
      'ryan', 'sophie', 'olivia', 'james', 'benjamin', 'lucy', 'hannah',
      'samuel', 'margaret', 'anne', 'simon', 'charlotte', 'emily',
      'daniel', 'george', 'harry', 'jack', 'oliver'
    ];

    final german = [
      'michael', 'thomas', 'andreas', 'stefan', 'werner', 'heinrich',
      'max', 'hans', 'franz', 'klaus', 'uwe', 'dirk', 'thorsten'
    ];

    final french = [
      'jean', 'pierre', 'marc', 'philippe', 'nicolas', 'antoine',
      'marie', 'claire', 'sophie', 'cecile', 'nathalie', 'isabelle'
    ];

    final spanish = [
      'juan', 'carlos', 'miguel', 'francisco', 'david', 'javier',
      'maria', 'ana', 'carmen', 'isabel', 'elena', 'rosa'
    ];

    final italian = [
      'marco', 'luca', 'giovanni', 'paolo', 'stefano', 'andrea',
      'maría', 'giulia', 'sara', 'chiara', 'francesca', 'laura'
    ];

    final chinese = [
      'wei', 'ming', 'fang', 'mei', 'hong', 'jun', 'hui',
      'yan', 'jing', 'bo', 'yu', 'li', 'wang', 'zhang'
    ];

    final japanese = [
      'yuki', 'kenji', 'takeshi', 'akira', 'haruki', 'sota',
      'sakura', 'hinata', 'yuna', 'aoi', 'mika', 'ren'
    ];

    final korean = [
      'min-jun', 'seo-yeon', 'ji-ho', 'yeon', 'ho-jin', 'seo',
      'min', 'ji', 'sung', 'kim', 'park', 'choi'
    ];

    final indian = [
      'arjun', 'rahul', 'vijay', 'amit', 'vikram', 'raj',
      'priya', 'anita', 'sunita', 'kavita', 'deepa', 'meera'
    ];

    if (americanBritish.contains(lower)) return '🇺🇸';
    if (german.contains(lower)) return '🇩🇪';
    if (french.contains(lower)) return '🇫🇷';
    if (spanish.contains(lower)) return '🇪🇸';
    if (italian.contains(lower)) return '🇮🇹';
    if (chinese.contains(lower)) return '🇨🇳';
    if (japanese.contains(lower)) return '🇯🇵';
    if (korean.contains(lower)) return '🇰🇷';
    if (indian.contains(lower)) return '🇮🇳';

    // Default to US/UK for western names
    return '🌏';
  }

  static bool _isBalineseName(String name) {
    final balinesePrefixes = ['wayan', 'made', 'ketut', 'nyoman', 'putu', 'gede', 'komang', 'agung', 'putra'];
    for (final prefix in balinesePrefixes) {
      if (name.startsWith('$prefix ') || name.startsWith(prefix)) return true;
    }
    return false;
  }

  static bool _isThaiName(String name) {
    final thaiPatterns = ['somchai', 'somsri', 'chai', 'suda', 'porntip', 'montri', 'anucha', 'krit', 'kriangsak'];
    for (final p in thaiPatterns) {
      if (name.contains(p)) return true;
    }
    return false;
  }

  static bool _isVietnameseName(String name) {
    final vietnamesePatterns = ['nguyen', 'tran', 'pham', 'le', 'hoang', 'vu', 'dang', 'bui', 'do', 'ho'];
    for (final p in vietnamesePatterns) {
      if (name.startsWith(p) || name.contains(' $p')) return true;
    }
    return false;
  }

  static bool _isFilipinoName(String name) {
    final filipinoPatterns = ['jose', 'maria', 'juan', 'pedro', 'ana', 'carlos', 'ramon', 'fernando', 'rodrigo'];
    for (final p in filipinoPatterns) {
      if (name.startsWith(p) || name.startsWith('$p ')) return true;
    }
    return false;
  }

  static bool _isMalayName(String name) {
    final malayPatterns = ['ahmad', 'muhammad', 'abdullah', 'zainal', 'haziq', 'aidil', 'fikri', 'akmal'];
    for (final p in malayPatterns) {
      if (name.startsWith(p)) return true;
    }
    return false;
  }

  static bool _isMyanmarName(String name) {
    final myanmarPatterns = ['maung', 'ko', 'u', 'saw', 'kya', 'thu', 'myo', 'tun', 'aung', 'zaw'];
    for (final p in myanmarPatterns) {
      if (name.startsWith('$p ') || name.startsWith(p)) return true;
    }
    return false;
  }

  static bool _isChineseName(String name) {
    final chineseSurnames = ['wang', 'li', 'zhang', 'liu', 'chen', 'yang', 'huang', 'zhao', 'wu', 'xu', 'sun', 'ma', 'zhu', 'hu', 'guo', 'he'];
    for (final s in chineseSurnames) {
      if (name.startsWith('$s ') || name.startsWith(s)) return true;
    }
    return false;
  }

  static bool _isKoreanName(String name) {
    final koreanSurnames = ['kim', 'lee', 'park', 'choi', 'jung', 'kang', 'yoon', 'jang', 'lim'];
    for (final s in koreanSurnames) {
      if (name.startsWith('$s ') || name.startsWith(s)) return true;
    }
    return false;
  }

  static bool _isJapaneseName(String name) {
    final japaneseSuffixes = ['ko', 'ki', 'mi', 'ya', 'ta', 'na', 'ra', 'shi', 'to', 'no', 'ri'];
    final parts = name.split(' ');
    if (parts.length >= 2) {
      final lastPart = parts.last.toLowerCase();
      for (final suffix in japaneseSuffixes) {
        if (lastPart.endsWith(suffix) && lastPart.length > 2) return true;
      }
    }
    return false;
  }

  static bool _isIndianName(String name) {
    final indianPrefixes = ['arjun', 'rahul', 'vikram', 'amit', 'priya', 'anita', 'sunita', 'deepa', 'neha', 'kiran', 'raj', 'amit', 'sumit', 'vijay'];
    for (final p in indianPrefixes) {
      if (name.startsWith('$p ') || name.startsWith(p)) return true;
    }
    return false;
  }

  static bool _isWesternName(String lower, String original) {
    // Check if mostly ASCII letters (western names rarely have unicode in first name position)
    final firstName = original.split(' ').first;
    final isAscii = firstName.runes.every((r) => r < 128);
    if (!isAscii) return false;

    // Common western first names
    final western = ['sarah', 'michael', 'emma', 'james', 'david', 'lisa', 'john', 'jennifer', 'william', 'elizabeth', 'richard', 'jessica', 'tom', 'ryan', 'sophie', 'olivia', 'benjamin', 'lucy', 'anna', 'nicholas', 'peter', 'paul', 'andrew', 'stuart', 'mark', 'robert', 'mary', 'patricia', 'barbara', 'susan', 'margaret', 'dorothy', 'harry', 'oliver', 'jack', 'george', 'charlotte', 'amelia', 'isabella', 'harriet', 'catherine', 'thomas', 'charles', 'samuel', 'ethan', 'jacob', 'mason', 'logan', 'alexander', 'henry', 'oscar', 'lucas', 'matthew'];
    for (final name in western) {
      if (lower.startsWith('$name ') || lower.startsWith(name)) return true;
    }
    return false;
  }
}

/// Icon button for app bars — hover glow on desktop.
class IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const IconBtn({super.key, required this.icon, required this.onPressed});

  @override
  State<IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<IconBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(widget.icon, color: Colors.white.withOpacity(_isHovered ? 1 : 0.7), size: 20),
        ),
      ),
    );
  }
}

/// Grid background painter for dark-themed wide-layout screens.
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
