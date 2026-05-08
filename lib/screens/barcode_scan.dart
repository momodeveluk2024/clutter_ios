import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/models/food.dart';

/// Phase 4 barcode scanning. Live camera scan → backend lookup by EAN/UPC
/// at /v1/foods/barcode/{barcode}. Pop with the FoodDetail on hit; on
/// miss, navigate to a "Couldn't find it — add manually" screen
/// (caller's responsibility — we just pop with null).
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  bool _resolving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    setState(() => _resolving = true);
    try {
      final response = await widget.api.get('${ApiEndpoints.foods}/barcode/$raw');
      final detail = FoodDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
      if (!mounted) return;
      Navigator.of(context).pop(detail);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode not found in catalog')),
      );
      setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
