import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/providers/notification_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, notif, _) {
            if (notif.isLoading) {
              return const Center(
                child: NVLoader(label: 'Loading preferences…'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      NVCircleIconButton(
                        icon: Icons.chevron_left,
                        background: c.surface,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Body ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // ═══════════════════════════════════════
                      //  MEAL REMINDERS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.restaurant_rounded,
                        label: 'MEAL REMINDERS',
                        color: NV.accent,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Meal reminders',
                        subtitle: 'Get notified at meal times to log your food',
                        value: notif.mealReminders,
                        onChanged: notif.setMealReminders,
                      ),
                      if (notif.mealReminders) ...[
                        const SizedBox(height: 8),
                        _MealTimeRow(
                          emoji: '🌅',
                          label: 'Breakfast',
                          time: notif.breakfastTime,
                          onTap: () => _pickTime(
                            context,
                            notif.breakfastTime,
                            notif.setBreakfastTime,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MealTimeRow(
                          emoji: '☀️',
                          label: 'Lunch',
                          time: notif.lunchTime,
                          onTap: () => _pickTime(
                            context,
                            notif.lunchTime,
                            notif.setLunchTime,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MealTimeRow(
                          emoji: '🌙',
                          label: 'Dinner',
                          time: notif.dinnerTime,
                          onTap: () => _pickTime(
                            context,
                            notif.dinnerTime,
                            notif.setDinnerTime,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  NUTRIENT TIPS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.eco_rounded,
                        label: 'NUTRIENT TIPS',
                        color: vitaminColors['C']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Daily recommendations',
                        subtitle:
                            'Personalised food suggestions with images based on your nutrient gaps',
                        value: notif.nutrientTips,
                        onChanged: notif.setNutrientTips,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  STREAK ALERTS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.local_fire_department_rounded,
                        label: 'STREAK ALERTS',
                        color: vitaminColors['A']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Streak motivation',
                        subtitle:
                            "Evening reminder to keep your logging streak alive",
                        value: notif.streakAlerts,
                        onChanged: notif.setStreakAlerts,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  HYDRATION
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.water_drop_rounded,
                        label: 'HYDRATION',
                        color: vitaminColors['B12']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Water reminders',
                        subtitle:
                            'Gentle reminders every 2 hours from 8 AM to 8 PM',
                        value: notif.hydration,
                        onChanged: notif.setHydration,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  WEEKLY REPORT
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.bar_chart_rounded,
                        label: 'WEEKLY REPORT',
                        color: vitaminColors['D']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Weekly summary',
                        subtitle: 'Sunday evening report of your nutrient coverage for the week',
                        value: notif.weeklySummary,
                        onChanged: notif.setWeeklySummary,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  CALORIE ALERTS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.bolt_rounded,
                        label: 'CALORIE ALERTS',
                        color: vitaminColors['B12']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'Low calorie reminder',
                        subtitle:
                            "Heads-up after 8 PM if you're below 50% of your calorie goal and haven't logged in 6 hours",
                        value: notif.lowCalorieAlerts,
                        onChanged: notif.setLowCalorieAlerts,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  AI INSIGHTS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI INSIGHTS',
                        color: vitaminColors['K']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _ToggleCard(
                        title: 'AI feature tips',
                        subtitle: 'Reminders to try AI meal photo analysis',
                        value: notif.aiInsights,
                        onChanged: notif.setAiInsights,
                      ),

                      const SizedBox(height: 22),

                      // ═══════════════════════════════════════
                      //  TEST NOTIFICATION
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.send_rounded,
                        label: 'TEST',
                        color: vitaminColors['Protein']!.fill,
                      ),
                      const SizedBox(height: 8),
                      _TestPushButton(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay current,
    Future<void> Function(TimeOfDay) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: NV.accent,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await onPicked(picked);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: c.textMuted,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TOGGLE CARD
// ═══════════════════════════════════════════════════════════════

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: NV.accent,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MEAL TIME ROW
// ═══════════════════════════════════════════════════════════════

class _MealTimeRow extends StatelessWidget {
  const _MealTimeRow({
    required this.emoji,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final timeStr = _formatTime(time);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: NV.accent.withValues(alpha: dark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NV.accent,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_outlined,
                size: 15,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _TestPushButton extends StatefulWidget {
  @override
  State<_TestPushButton> createState() => _TestPushButtonState();
}

class _TestPushButtonState extends State<_TestPushButton> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await context.read<NotificationProvider>().sendTestPush();
      if (!mounted) return;
      final messages = <String>[];
      if (result.localShown) {
        messages.add('Local heads-up shown.');
      }
      if (result.remoteDevices > 0) {
        messages.add(
          'FCM dispatched to ${result.remoteDevices} device'
          '${result.remoteDevices == 1 ? '' : 's'}.',
        );
      } else if (!result.localShown) {
        messages.add('Could not show notification — check OS permissions.');
      }
      messenger.showSnackBar(SnackBar(content: Text(messages.join(' '))));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not send test: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return NVCard(
      padding: const EdgeInsets.all(NVSpace.x4),
      onTap: _sending ? null : _send,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: vitaminColors['Protein']!.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: vitaminColors['Protein']!.fill,
            ),
          ),
          const SizedBox(width: NVSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send test notification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fires a heads-up push to every device on this account so you can verify FCM and OS permissions.',
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: NVSpace.x3),
          if (_sending)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
        ],
      ),
    );
  }
}
