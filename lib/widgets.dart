import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'core/api/api_endpoints.dart';
import 'core/models/nutrient_reference.dart';
import 'core/models/visual_catalog.dart';
import 'theme.dart';

// ═══════════════════════════════════════════════════════════════
//  IMAGES
// ═══════════════════════════════════════════════════════════════

/// Striped placeholder — signals "real food photo goes here".
/// Spec: no gradients on surfaces; the placeholder uses a flat tinted fill
/// with a faint background icon.
class PhotoPlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final double? width;
  final double radius;
  final String tone;

  const PhotoPlaceholder({
    super.key,
    this.label = '',
    this.height = 120,
    this.width,
    this.radius = NVRadius.card,
    this.tone = 'warm',
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final initials = _initialsFor(label, fallback: 'NV');
    final base = tone == 'warm' ? const Color(0xFFB98B55) : NV.accent;
    final bg = dark
        ? Color.alphaBlend(base.withValues(alpha: 0.10), NV.surfaceDark)
        : Color.alphaBlend(base.withValues(alpha: 0.08), NV.surfaceMuted);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -height * 0.10,
              bottom: -height * 0.16,
              child: Icon(
                Icons.eco_outlined,
                size: height * 0.78,
                color: base.withValues(alpha: dark ? 0.10 : 0.08),
              ),
            ),
            Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: math.max(10, height * 0.16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: base.withValues(alpha: dark ? 0.92 : 0.78),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodPhoto extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final String? category;
  final double height;
  final double? width;
  final double radius;
  final String tone;
  final BoxFit fit;

  const FoodPhoto({
    super.key,
    required this.label,
    this.imageUrl,
    this.category,
    this.height = 120,
    this.width,
    this.radius = NVRadius.card,
    this.tone = 'warm',
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim();
    final slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fallbackAsset = 'assets/foods/$slug.jpg';

    if (raw == null || raw.isEmpty) {
      return _buildAssetFallback(fallbackAsset);
    }
    // User-uploaded photos come back as a relative path like
    // `/uploads/foods/<id>/<file>.jpg`; resolve it against the API origin so
    // CachedNetworkImage can actually fetch it instead of erroring out and
    // falling back to the generic category visual. Absolute URLs (the curated
    // Unsplash catalog images) pass through untouched.
    final url = ApiEndpoints.mediaUrl(raw);
    if (url.isEmpty) {
      return _buildAssetFallback(fallbackAsset);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width ?? double.infinity,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
        placeholder: (context, url) =>
            _ShimmerBox(width: width, height: height, radius: 0),
        errorWidget: (context, url, error) =>
            _buildAssetFallback(fallbackAsset),
      ),
    );
  }

  Widget _buildAssetFallback(String assetPath) {
    final catUrl = category != null && category!.isNotEmpty
        ? categoryVisualFor(category!).imageUrl
        : fallbackCategoryVisual.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: width ?? double.infinity,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Image.network(
          catUrl,
          width: width ?? double.infinity,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => PhotoPlaceholder(
            label: label,
            height: height,
            width: width,
            radius: radius,
            tone: tone,
          ),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.size = 72,
    this.editable = false,
    this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final double size;
  final bool editable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final url = avatarUrl?.trim() ?? '';
    final fg = dark ? NV.textDark : NV.accentDeep;

    final content = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: dark ? NV.accent.withValues(alpha: 0.22) : NV.accentSoft,
        alignment: Alignment.center,
        child: url.isEmpty
            ? Text(
                _initialsFor(displayName, fallback: '?'),
                style: TextStyle(
                  color: fg,
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w700,
                ),
              )
            : CachedNetworkImage(
                imageUrl: ApiEndpoints.mediaUrl(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Text(
                  _initialsFor(displayName, fallback: '?'),
                  style: TextStyle(
                    color: fg,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.all(2),
          child: content,
        ),
        if (editable)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: NV.surfaceInk,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: const Color(0xFFFAFAFA),
                size: size * 0.16,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return avatar;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: avatar,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  NUTRIENT VISUALS
// ═══════════════════════════════════════════════════════════════

class VitaminChip extends StatelessWidget {
  final String code;
  final double size;
  const VitaminChip({super.key, required this.code, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = vitaminColors[code] ?? vitaminColors['C']!;
    final visual = nutrientVisualFor(code);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? hue.fill.withValues(alpha: 0.20) : hue.bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(visual.icon, size: size * 0.46, color: hue.fill),
    );
  }
}

class NutrientPill extends StatelessWidget {
  const NutrientPill({
    super.key,
    required this.code,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  final String code;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final visual = nutrientVisualFor(code);
    final bg = dark ? c.surfaceMuted : NV.surfaceMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NVRadius.chip),
        child: Container(
          padding: EdgeInsets.fromLTRB(6, 5, compact ? 9 : 11, 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(NVRadius.chip),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 20 : 22,
                height: compact ? 20 : 22,
                decoration: BoxDecoration(
                  color: dark
                      ? visual.accent.withValues(alpha: 0.22)
                      : visual.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  visual.icon,
                  size: compact ? 11 : 12,
                  color: visual.accent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NutrientCard extends StatelessWidget {
  const NutrientCard({
    super.key,
    required this.nutrient,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final NutrientReference nutrient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final hue = vitaminColors[nutrient.code] ?? vitaminColors['D']!;
    final visual = nutrientVisualFor(nutrient.code);
    final bg = dark ? hue.fill.withValues(alpha: 0.18) : hue.bg;
    return NVCard(
      onTap: onTap,
      radius: compact ? NVRadius.cardSm : NVRadius.card,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
            ),
            child: Icon(visual.icon, size: compact ? 20 : 24, color: hue.fill),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nutrient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (nutrient.dailyTarget > 0)
                      Text(
                        nutrient.targetLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  nutrient.summary,
                  maxLines: compact ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right, size: 20, color: c.textMuted),
        ],
      ),
    );
  }
}

class NutrientArtwork extends StatelessWidget {
  const NutrientArtwork({
    super.key,
    required this.code,
    required this.name,
    this.height = 160,
    this.radius = NVRadius.cardLg,
  });

  final String code;
  final String name;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = vitaminColors[code] ?? vitaminColors['C']!;
    final visual = nutrientVisualFor(code);
    final icon = visual.icon;
    final bg = dark ? hue.fill.withValues(alpha: 0.20) : hue.bg;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        color: bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -28,
              top: -24,
              child: Icon(
                icon,
                size: height * 0.86,
                color: hue.fill.withValues(alpha: dark ? 0.14 : 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(NVSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NVEyebrow(_artLabel(code), color: hue.fill),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      VitaminChip(code: code, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: dark ? NV.textDark : NV.text,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _artLabel(String code) {
    if (code.startsWith('B')) return 'B-COMPLEX';
    if ([
      'Fe',
      'Ca',
      'Zn',
      'Mg',
      'Kp',
      'Na',
      'P',
      'Se',
      'Mn',
      'S',
    ].contains(code)) {
      return 'MINERAL';
    }
    if (['Protein', 'Fiber', 'Carbs', 'Fat'].contains(code)) {
      return 'MACRO';
    }
    return 'VITAMIN';
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROGRESS — flat, no gradients, tabular numerals
// ═══════════════════════════════════════════════════════════════

class RingProgress extends StatelessWidget {
  final double pct;
  final double size;
  final double stroke;
  final Color? color;
  final String label;
  final String? sub;

  const RingProgress({
    super.key,
    this.pct = 0.7,
    this.size = 88,
    this.stroke = 8,
    this.color,
    required this.label,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final ringColor = color ?? NV.accent;
    final trackColor = dark ? NV.borderDark : const Color(0xFFE5E7EB);
    final target = pct.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: NVMotion.slow,
      curve: NVMotion.standard,
      builder: (context, value, _) {
        final animatedLabel = label.endsWith('%')
            ? '${(value * 100).round()}%'
            : label;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  pct: value,
                  color: ringColor,
                  track: trackColor,
                  stroke: stroke,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedLabel,
                    style: nvNumber(
                      size * 0.24,
                      color: c.text,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sub!,
                        style: TextStyle(
                          fontSize: math.max(9, size * 0.10),
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color, track;
  final double stroke;
  _RingPainter({
    required this.pct,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, trackPaint);

    if (pct <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.pct != pct || old.color != color || old.track != track;
}

class BarProgress extends StatelessWidget {
  final double pct;
  final Color? color;
  final double height;
  const BarProgress({super.key, this.pct = 0.5, this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track = dark ? NV.borderDark : const Color(0xFFE5E7EB);
    final fill = color ?? NV.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: NVMotion.slow,
      curve: NVMotion.standard,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Container(
            height: height,
            color: track,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CARDS, BUTTONS, INPUTS
// ═══════════════════════════════════════════════════════════════

/// Hairline-bordered card. No shadow by default — the border is the affordance.
class NVCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? background;
  final bool noBorder;
  final VoidCallback? onTap;

  /// If true, applies a subtle long-distance ambient shadow (used for hero cards).
  final bool elevated;

  const NVCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = NVRadius.card,
    this.background,
    this.noBorder = false,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final bg = background ?? c.surface;
    final shape = BorderRadius.circular(radius);

    final box = AnimatedContainer(
      duration: NVMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: shape,
        border: noBorder ? null : Border.all(color: c.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.32)
                      : const Color(0xFF0F1E14).withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: shape, child: box),
    );
  }
}

/// Primary CTA. Default is **ink** (warm near-black) per the design system.
/// Set `accent: true` to use the brand green — reserve for the single
/// hero callout per viewport.
class NVPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final double height;
  final double? width;
  final double radius;
  final bool accent;
  final bool loading;

  const NVPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.height = 54,
    this.width,
    this.radius = 999,
    this.accent = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent ? NV.accent : NV.surfaceInk;
    final fg = accent ? Colors.white : const Color(0xFFFAFAFA);
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.55),
          disabledForegroundColor: fg.withValues(alpha: 0.75),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Secondary action — pill-shaped outlined.
class NVSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final double height;

  const NVSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          backgroundColor: c.surface,
          side: BorderSide(color: c.border),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.05,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 16, color: c.text),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Small circular header button (back / bookmark / etc.). Flat surface.
class NVCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;
  final double size;
  const NVCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.foreground,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Material(
      color: background ?? c.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
          ),
          child: Icon(icon, size: 18, color: foreground ?? c.text),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TYPE — eyebrows, large titles, big numbers
// ═══════════════════════════════════════════════════════════════

class NVEyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  const NVEyebrow(this.text, {super.key, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text.toUpperCase(),
        style: nvEyebrow(color: color ?? c.textMuted),
      ),
    );
  }
}

/// Backwards-compatible alias kept for existing callers.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;
  const SectionLabel(this.text, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return NVEyebrow(text, padding: padding);
  }
}

/// Big metric — for hero numbers ("1,840 / 2,200 kcal").
class NVMetric extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final TextAlign align;
  final double valueSize;
  final Color? valueColor;

  const NVMetric({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.align = TextAlign.start,
    this.valueSize = 36,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          NVEyebrow(label!, color: c.textMuted),
          const SizedBox(height: NVSpace.x2),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: nvNumber(
                valueSize,
                color: valueColor ?? c.text,
                weight: FontWeight.w700,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit!,
                  style: TextStyle(
                    fontSize: math.max(11, valueSize * 0.32),
                    color: c.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Section heading row: large title + optional trailing action.
class NVSectionHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const NVSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  NVEyebrow(eyebrow!),
                  const SizedBox(height: NVSpace.x1),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BENTO TILE / STAT
// ═══════════════════════════════════════════════════════════════

/// A single tile in a bento grid: eyebrow, optional icon, big value.
class NVBentoTile extends StatelessWidget {
  final String eyebrow;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? background;

  const NVBentoTile({
    super.key,
    required this.eyebrow,
    required this.child,
    this.icon,
    this.iconColor,
    this.onTap,
    this.padding = const EdgeInsets.all(NVSpace.x4),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      onTap: onTap,
      padding: padding,
      background: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(child: NVEyebrow(eyebrow)),
              if (icon != null)
                Icon(icon, size: 16, color: iconColor ?? c.textMuted),
            ],
          ),
          const SizedBox(height: NVSpace.x4),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SELECT FIELD (refreshed)
// ═══════════════════════════════════════════════════════════════

class NVSelectField extends StatelessWidget {
  const NVSelectField({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.value,
    this.display,
  });

  final String label;
  final String? value;
  final List<String> values;
  final String Function(String value)? display;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final displayValue = value == null ? 'Choose' : _display(value!);
    return Padding(
      padding: const EdgeInsets.only(bottom: NVSpace.x3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(NVRadius.field),
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(NVRadius.field),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NVEyebrow(label, color: c.textMuted),
                      const SizedBox(height: 4),
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value == null ? c.textMuted : c.text,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more_rounded, color: c.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final dark = Theme.of(sheetContext).brightness == Brightness.dark;
        final c = NVColors(dark);
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(NVRadius.cardLg),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                ...values.map((option) {
                  final selected = option == value;
                  return Material(
                    color: selected
                        ? (dark
                              ? NV.accent.withValues(alpha: 0.16)
                              : NV.accentSoft)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(NVRadius.field),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(NVRadius.field),
                      onTap: () => Navigator.of(sheetContext).pop(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _display(option),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: c.text,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_rounded,
                                color: NV.accent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  String _display(String value) => display?.call(value) ?? value;
}

// ═══════════════════════════════════════════════════════════════
//  SHIMMER / SKELETON
// ═══════════════════════════════════════════════════════════════

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = NVRadius.cardSm,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF1B2420) : const Color(0xFFEDEFE8),
      highlightColor: dark ? const Color(0xFF22302A) : Colors.white,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1B2420) : const Color(0xFFEDEFE8),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class NVSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const NVSkeleton({super.key, this.width, this.height = 14, this.radius = 6});

  @override
  Widget build(BuildContext context) =>
      _ShimmerBox(width: width, height: height, radius: radius);
}

// ═══════════════════════════════════════════════════════════════
//  FROSTED OVERLAY (used for sliver hero bars on photo screens)
// ═══════════════════════════════════════════════════════════════

class NVFrosted extends StatelessWidget {
  final Widget child;
  final double sigma;
  final Color? tint;
  const NVFrosted({super.key, required this.child, this.sigma = 14, this.tint});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          color:
              tint ??
              (dark
                  ? Colors.black.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.62)),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════

String _initialsFor(String value, {String fallback = 'NV'}) {
  final words = value
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .toList();
  if (words.isEmpty) return fallback;
  return words.map((word) => word[0]).join().toUpperCase();
}
