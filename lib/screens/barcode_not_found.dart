import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

/// Shown after a scanned barcode has no match in the catalog. Offers the
/// user two recovery paths: send the meal through the AI photo analyzer,
/// or fill in the product details by hand so the food can be saved and
/// reviewed by an admin.
class BarcodeNotFoundScreen extends StatefulWidget {
  const BarcodeNotFoundScreen({super.key, required this.barcode});

  final String barcode;

  @override
  State<BarcodeNotFoundScreen> createState() => _BarcodeNotFoundScreenState();
}

class _BarcodeNotFoundScreenState extends State<BarcodeNotFoundScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _opening = false;

  Future<void> _scanWithAi() async {
    if (_opening) return;
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AiPhotoSourceSheet(),
    );
    if (source == null || !mounted) return;
    setState(() => _opening = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (picked == null || !mounted) return;
      final now = DateTime.now();
      final loggedOn =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      context.pushReplacement(
        '/app/ai/meal-photo',
        extra: <String, String>{
          'imagePath': picked.path,
          'mealType': _defaultMealType(now),
          'loggedOn': loggedOn,
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not open photo picker.')),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _addManually() {
    HapticFeedback.selectionClick();
    context.pushReplacement(
      '/app/barcode-scan/contribute',
      extra: widget.barcode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Barcode not found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.text,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: NV.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: NV.accent,
                  size: 32,
                ),
              ),
              Text(
                'We couldn\'t recognise that barcode',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.barcode.isEmpty
                    ? 'Pick how you\'d like to log this meal.'
                    : 'Barcode ${widget.barcode} isn\'t in the catalog yet. Pick how you\'d like to log it.',
                style: TextStyle(
                  fontSize: 14,
                  color: c.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _OptionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Scan with AI',
                subtitle:
                    'Take or pick a photo of the food. Our AI will estimate the nutrients.',
                onTap: _opening ? null : _scanWithAi,
              ),
              const SizedBox(height: 14),
              _OptionCard(
                icon: Icons.edit_note_rounded,
                title: 'Add info manually',
                subtitle:
                    'Type the name and nutrition facts from the label. We\'ll send it to admin for verification.',
                onTap: _opening ? null : _addManually,
              ),
              const Spacer(),
              if (_opening)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(NVRadius.cardLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(NVRadius.cardLg),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NV.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: NV.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPhotoSourceSheet extends StatelessWidget {
  const _AiPhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: c.text),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: c.text),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

String _defaultMealType(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'breakfast';
  if (h < 16) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}
