import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Barcode scanner stub for simulator builds.
/// On a real device, the camera would be used for scanning.
/// On simulator, a manual barcode entry UI is shown instead.
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      appBar: AppBar(
        backgroundColor: PremiumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: PremiumColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Barkod Tarayıcı',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: PremiumColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scanner icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: PremiumColors.coralAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: PremiumColors.coralAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Barkod Tarama',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: PremiumColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamera şu anda kullanılamıyor.\nBarkod numarasını manuel olarak girebilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: PremiumColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Manual barcode entry
            TextField(
              controller: _barcodeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Barkod Numarası',
                hintText: '8699999999999',
                prefixIcon: const Icon(Icons.dialpad, color: PremiumColors.pillBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PremiumColors.coralAccent, width: 2),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  final code = _barcodeController.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.of(context).pop(code);
                  }
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  'Barkodu Onayla',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumColors.coralAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
