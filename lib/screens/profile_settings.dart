import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/models/reminder.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reminder_provider.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/nv_loader.dart';

class ProfileGoalsScreen extends StatefulWidget {
  const ProfileGoalsScreen({super.key});

  @override
  State<ProfileGoalsScreen> createState() => _ProfileGoalsScreenState();
}

class _ProfileGoalsScreenState extends State<ProfileGoalsScreen> {
  late final Set<String> _selected;
  var _saving = false;

  static const _options = [
    'Immunity',
    'Energy',
    'Bone health',
    'Heart health',
    'Focus',
    'Fitness',
    'Iron support',
    'Better digestion',
  ];

  @override
  void initState() {
    super.initState();
    _selected = {...?context.read<AuthProvider>().user?.goals};
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Goals',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Choose your focus'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((goal) {
              final selected = _selected.contains(goal);
              return FilterChip(
                label: Text(goal),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    value ? _selected.add(goal) : _selected.remove(goal);
                  });
                },
              );
            }).toList(),
          ),
          const Spacer(),
          NVPrimaryButton(
            label: _saving ? 'Saving...' : 'Save goals',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updatePreferences(
        goals: _selected.toList(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ProfileBodyScreen extends StatefulWidget {
  const ProfileBodyScreen({super.key});

  @override
  State<ProfileBodyScreen> createState() => _ProfileBodyScreenState();
}

class _ProfileBodyScreenState extends State<ProfileBodyScreen> {
  late final TextEditingController _name;
  late final TextEditingController _dob;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String? _sex;
  String? _activity;
  String? _pregnancy;
  var _saving = false;
  var _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.displayName ?? '');
    _dob = TextEditingController(text: user?.dateOfBirth ?? '');
    _height = TextEditingController(text: _number(user?.heightCm));
    _weight = TextEditingController(text: _number(user?.weightKg));
    _sex = user?.sex;
    _activity = user?.activityLevel;
    _pregnancy = user?.pregnancyStatus;
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Personal details',
      child: ListView(
        children: [
          _AvatarEditor(
            displayName: _name.text.trim().isEmpty
                ? 'Nutrimate user'
                : _name.text.trim(),
            avatarUrl: context.watch<AuthProvider>().user?.avatarUrl,
            uploading: _avatarUploading,
            onTap: _pickAvatar,
          ),
          const SizedBox(height: 18),
          _TextField(label: 'Display name', controller: _name),
          _ChoiceField(
            label: 'Sex',
            value: _sex,
            values: const ['female', 'male', 'other'],
            onChanged: (value) => setState(() => _sex = value),
          ),
          _TextField(
            label: 'Date of birth',
            hint: 'YYYY-MM-DD',
            controller: _dob,
            keyboardType: TextInputType.datetime,
          ),
          _TextField(
            label: 'Height',
            hint: 'cm',
            controller: _height,
            keyboardType: TextInputType.number,
          ),
          _TextField(
            label: 'Weight',
            hint: 'kg',
            controller: _weight,
            keyboardType: TextInputType.number,
          ),
          _ChoiceField(
            label: 'Activity level',
            value: _activity,
            values: const [
              'sedentary',
              'light',
              'moderate',
              'active',
              'very_active',
            ],
            onChanged: (value) => setState(() => _activity = value),
          ),
          _ChoiceField(
            label: 'Pregnancy status',
            value: _pregnancy,
            values: const ['none', 'pregnant', 'postpartum', 'trying'],
            onChanged: (value) => setState(() => _pregnancy = value),
          ),
          const SizedBox(height: 20),
          NVPrimaryButton(
            label: _saving ? 'Saving...' : 'Save details',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        displayName: _name.text.trim(),
        sex: _sex,
        dateOfBirth: _dob.text.trim(),
        heightCm: double.tryParse(_height.text.trim()),
        weightKg: double.tryParse(_weight.text.trim()),
        activityLevel: _activity,
        pregnancyStatus: _pregnancy,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    // Avatars render as a small circle (~96px) — full-resolution iPhone
    // shots are 5-12MB and blow past the server's 8MB multipart cap.
    // Resize + JPEG-compress on-device so the upload always fits.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _avatarUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await auth.uploadAvatarBytes(
        bytes: bytes,
        filename: picked.name,
        contentType: picked.mimeType ?? _contentTypeForFilename(picked.name),
      );
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }
}

class ProfileDietScreen extends StatefulWidget {
  const ProfileDietScreen({super.key});

  @override
  State<ProfileDietScreen> createState() => _ProfileDietScreenState();
}

class _ProfileDietScreenState extends State<ProfileDietScreen> {
  late final TextEditingController _allergens;
  String? _pattern;
  var _saving = false;

  static const _patterns = [
    'Omnivore',
    'Pescatarian',
    'Vegetarian',
    'Vegan',
    'Mediterranean',
    'High-protein',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _pattern = user?.dietaryPattern;
    _allergens = TextEditingController(text: user?.allergens.join(', ') ?? '');
  }

  @override
  void dispose() {
    _allergens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Dietary preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceField(
            label: 'Diet pattern',
            value: _pattern,
            values: _patterns,
            onChanged: (value) => setState(() => _pattern = value),
          ),
          _TextField(
            label: 'Allergens',
            hint: 'peanuts, shellfish',
            controller: _allergens,
          ),
          const Spacer(),
          NVPrimaryButton(
            label: _saving ? 'Saving...' : 'Save preferences',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updatePreferences(
        dietaryPattern: _pattern,
        allergens: _allergens.text
            .split(',')
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .toList(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ProfileRemindersScreen extends StatefulWidget {
  const ProfileRemindersScreen({super.key});

  @override
  State<ProfileRemindersScreen> createState() => _ProfileRemindersScreenState();
}

class _ProfileRemindersScreenState extends State<ProfileRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Reminders',
      trailing: NVCircleIconButton(
        icon: Icons.add,
        onTap: () => _showReminderDialog(context),
      ),
      child: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.reminders.isEmpty) {
            return const Center(child: NVLoader(label: 'Loading reminders…'));
          }
          if (provider.reminders.isEmpty) {
            return NVCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No reminders yet. Add one to make logging easier.',
                style: TextStyle(color: NVColors(false).textMuted),
              ),
            );
          }
          return ListView.separated(
            itemBuilder: (context, index) =>
                _ReminderTile(reminder: provider.reminders[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: provider.reminders.length,
          );
        },
      ),
    );
  }
}

class ProfileUnitsScreen extends StatelessWidget {
  const ProfileUnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return _SettingsScaffold(
      title: 'Units',
      child: Column(
        children: [
          _OptionTile(
            title: 'Metric',
            subtitle: 'Centimeters and kilograms',
            selected: user?.units != 'imperial',
            onTap: () => _saveUnits(context, 'metric'),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            title: 'Imperial',
            subtitle: 'Feet, inches, and pounds',
            selected: user?.units == 'imperial',
            onTap: () => _saveUnits(context, 'imperial'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUnits(BuildContext context, String units) async {
    try {
      await context.read<AuthProvider>().updatePreferences(units: units);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }
}

class ProfileAppearanceScreen extends StatelessWidget {
  const ProfileAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance =
        context.watch<AuthProvider>().user?.appearance ?? 'light';
    return _SettingsScaffold(
      title: 'Appearance',
      child: Column(
        children: [
          _OptionTile(
            title: 'Light',
            subtitle: 'Bright and calm',
            selected: appearance == 'light',
            onTap: () => _save(context, 'light'),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            title: 'Dark',
            subtitle: 'Dim, high contrast surfaces',
            selected: appearance == 'dark',
            onTap: () => _save(context, 'dark'),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            title: 'System',
            subtitle: 'Follow this device',
            selected: appearance == 'system',
            onTap: () => _save(context, 'system'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, String appearance) async {
    try {
      await context.read<AuthProvider>().updateAppearance(appearance);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }
}

class ProfileAboutScreen extends StatelessWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'About Nutrimate',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NVCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrimate',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0\nNutrition catalog powered by curated USDA-sourced data.',
                  style: TextStyle(
                    color: NVColors(false).textMuted,
                    height: 1.4,
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

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NVCircleIconButton(
                    icon: Icons.chevron_left,
                    background: c.surface,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                  ),
                  trailing ?? const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.displayName,
    required this.avatarUrl,
    required this.uploading,
    required this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            displayName: displayName,
            avatarUrl: avatarUrl,
            size: 70,
            editable: !uploading,
            onTap: uploading ? null : onTap,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile photo',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  uploading
                      ? 'Uploading...'
                      : 'Choose an image from this device.',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (uploading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: 'Upload profile photo',
              onPressed: onTap,
              icon: const Icon(Icons.upload_outlined),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final c = NVColors(Theme.of(context).brightness == Brightness.dark);
    return NVCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: NV.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                Text(
                  '${reminder.remindAt.toLocal()}'.split('.').first,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete reminder',
            onPressed: () =>
                context.read<ReminderProvider>().deleteReminder(reminder.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = NVColors(dark);
    final selectedBg = dark ? NV.accent.withValues(alpha: 0.16) : NV.accentSoft;
    return NVCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      background: selected ? selectedBg : null,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? NV.accent : c.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? (dark ? NV.textDark.withValues(alpha: 0.72) : NV.text)
                        : c.textMuted,
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

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return NVSelectField(
      label: label,
      value: values.contains(value) ? value : null,
      values: values,
      display: _humanize,
      onChanged: onChanged,
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

Future<void> _showReminderDialog(BuildContext context) async {
  final title = TextEditingController(text: 'Log meal');
  final body = TextEditingController();
  final provider = context.read<ReminderProvider>();
  final user = context.read<AuthProvider>().user;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('New reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: body,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final remindAt = DateTime.now().add(const Duration(hours: 2));
            await provider.createReminder(
              title: title.text.trim().isEmpty ? 'Log meal' : title.text.trim(),
              body: body.text,
              remindAt: remindAt,
              timezone: user?.timezone ?? 'UTC',
            );
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
  title.dispose();
  body.dispose();
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}

String _humanize(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _number(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}

String _contentTypeForFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}
