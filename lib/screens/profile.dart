import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/nutrition_provider.dart';
import '../theme.dart';
import '../widgets.dart';

const int _maxAvatarBytes = 6 * 1024 * 1024;
const Set<String> _allowedAvatarTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NutritionProvider>().loadStreak();
    });
  }

  Future<void> _pickAvatar() async {
    if (_avatarUploading) return;
    final auth = context.read<AuthProvider>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarUploading = true);
    try {
      final size = await picked.length();
      final contentType = picked.mimeType ?? _guessContentType(picked.name);
      if (size > _maxAvatarBytes) {
        throw const FormatException('Choose an image smaller than 6 MB.');
      }
      if (!_allowedAvatarTypes.contains(contentType)) {
        throw const FormatException('Choose a JPG, PNG, or WebP image.');
      }
      final bytes = await picked.readAsBytes();
      await auth.uploadAvatarBytes(
        bytes: bytes,
        filename: picked.name,
        contentType: contentType,
      );
      if (mounted) _showMessage('Profile photo updated');
    } catch (e) {
      if (mounted) _showErr(e);
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<void> _renameDialog(String current) async {
    final controller = TextEditingController(text: current);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 4),
        contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.text,
            letterSpacing: -0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.text,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceMuted,
                hintText: 'Your name',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NV.accent, width: 1.4),
                ),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: NV.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || newName == null || newName.isEmpty || newName == current) {
      return;
    }
    try {
      await context.read<AuthProvider>().updateProfile(displayName: newName);
    } catch (e) {
      if (mounted) _showErr(e);
    }
  }

  void _showErr(Object e) {
    final message = e is FormatException ? e.message : e.toString();
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _guessContentType(String filename) {
    final n = filename.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final auth = context.watch<AuthProvider>();
    final streak = context.watch<NutritionProvider>().streak;
    final user = auth.user;
    final displayName = user?.displayName ?? 'Nutrimate user';
    final email = user?.email ?? '';
    final isVerified = user?.isEmailVerified ?? false;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          // ──────── HERO ────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: _ProfileHero(
              displayName: displayName,
              email: email,
              avatarUrl: user?.avatarUrl,
              isVerified: isVerified,
              uploading: _avatarUploading,
              onAvatarTap: _pickAvatar,
              onRename: () => _renameDialog(displayName),
            ),
          ),

          // ──────── STREAK BENTO ────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StreakCard(
              days: streak,
              onTap: () => context.go('/app?tab=track'),
            ),
          ),

          // ──────── VERIFY EMAIL BANNER ────────
          if (!isVerified) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _VerifyBanner(onTap: () => context.go('/verify-email')),
            ),
          ],

          const SizedBox(height: 22),

          // ──────── PROFILE GROUP ────────
          const _SectionEyebrow('Profile'),
          _SettingsGroup(
            rows: [
              _SettingRow(
                icon: Icons.gps_fixed,
                title: 'Goals',
                detail: user?.goalsSummary ?? 'Set goals',
                onTap: () => context.push('/app/profile/goals'),
              ),
              _SettingRow(
                icon: Icons.person_outline,
                title: 'Personal details',
                detail: user?.bodySummary ?? 'Add details',
                onTap: () => context.push('/app/profile/body'),
              ),
              _SettingRow(
                icon: Icons.eco_outlined,
                title: 'Dietary preferences',
                detail: user?.dietSummary ?? 'Set preferences',
                onTap: () => context.push('/app/profile/diet'),
              ),
              _SettingRow(
                icon: Icons.notifications_outlined,
                title: 'Reminders',
                detail: user?.remindersSummary ?? 'Manage',
                onTap: () => context.push('/app/profile/reminders'),
              ),
              _SettingRow(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                detail: 'Manage',
                onTap: () => context.push('/app/profile/notifications'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ──────── PREFERENCES GROUP ────────
          const _SectionEyebrow('Preferences'),
          _SettingsGroup(
            rows: [
              _SettingRow(
                icon: Icons.straighten_outlined,
                title: 'Units',
                detail: user?.unitsLabel ?? 'Metric',
                onTap: () => context.push('/app/profile/units'),
              ),
              _SettingRow(
                icon: dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Appearance',
                detail: user?.appearanceLabel ?? (dark ? 'Dark' : 'Light'),
                onTap: () => context.push('/app/profile/appearance'),
              ),
              _SettingRow(
                icon: Icons.info_outline,
                title: 'About Nutrimate',
                detail: 'v1.0.0',
                onTap: () => context.push('/app/profile/about'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ──────── SIGN OUT ────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 52,
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  backgroundColor: c.surface,
                  foregroundColor: c.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: c.border),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),
          Center(
            child: Text(
              'NUTRIMATE · 1.0.0',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════ HERO ════════════
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.isVerified,
    required this.uploading,
    required this.onAvatarTap,
    required this.onRename,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool isVerified;
  final bool uploading;
  final VoidCallback onAvatarTap;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final vitA = vitaminColors['A']!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  NV.accent.withValues(alpha: 0.22),
                  vitA.fill.withValues(alpha: 0.12),
                ]
              : [NV.accentSoft, vitA.bg.withValues(alpha: 0.6)],
        ),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: UserAvatar(
                  displayName: displayName,
                  avatarUrl: avatarUrl,
                  size: 92,
                  editable: true,
                ),
              ),
              if (uploading)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRename,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border.withValues(alpha: 0.7)),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isVerified
                  ? NV.accent.withValues(alpha: dark ? 0.22 : 0.12)
                  : vitA.fill.withValues(alpha: dark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified
                      ? Icons.verified_rounded
                      : Icons.error_outline_rounded,
                  size: 13,
                  color: isVerified ? NV.accent : vitA.fill,
                ),
                const SizedBox(width: 6),
                Text(
                  isVerified ? 'Verified' : 'Unverified email',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: isVerified ? NV.accent : vitA.fill,
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

// ════════════ STREAK ════════════
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days, required this.onTap});

  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final vitA = vitaminColors['A']!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      vitA.fill.withValues(alpha: dark ? 0.3 : 0.18),
                      vitA.fill.withValues(alpha: dark ? 0.16 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 26,
                  color: vitA.fill,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          days.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: c.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'day streak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Keep logging to extend it',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.trending_up_rounded, size: 22, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════ VERIFY EMAIL BANNER ════════════
class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final vitA = vitaminColors['A']!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: vitA.fill.withValues(alpha: dark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: vitA.fill.withValues(alpha: 0.28)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: vitA.fill.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  size: 19,
                  color: vitA.fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Use the verification token to unlock sync',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: vitA.fill),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════ SECTION EYEBROW ════════════
class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w800,
          color: c.textMuted,
        ),
      ),
    );
  }
}

// ════════════ SETTINGS GROUP ════════════
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});
  final List<_SettingRow> rows;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Container(height: 1, color: c.border.withValues(alpha: 0.6)),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border.withValues(alpha: 0.5)),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 17, color: c.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (detail.isNotEmpty)
                Flexible(
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
