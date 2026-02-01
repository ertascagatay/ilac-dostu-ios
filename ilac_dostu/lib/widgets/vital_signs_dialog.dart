import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/measurement_model.dart';
import '../services/firestore_service.dart';

class VitalSignsDialog extends StatefulWidget {
  final String patientUid;
  final MeasurementType type;

  const VitalSignsDialog({
    super.key,
    required this.patientUid,
    required this.type,
  });

  @override
  State<VitalSignsDialog> createState() => _VitalSignsDialogState();
}

class _VitalSignsDialogState extends State<VitalSignsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Controllers
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.type) {
      case MeasurementType.bloodPressure:
        return 'Tansiyon Ölç';
      case MeasurementType.bloodSugar:
        return 'Şeker Ölç';
      case MeasurementType.weight:
        return 'Kilo Ölç';
      case MeasurementType.pulse:
        return 'Nabız Ölç';
      case MeasurementType.temperature:
        return 'Ateş Ölç';
    }
  }

  String get _unit {
    switch (widget.type) {
      case MeasurementType.bloodPressure:
        return 'mmHg';
      case MeasurementType.bloodSugar:
        return 'mg/dL';
      case MeasurementType.weight:
        return 'kg';
      case MeasurementType.pulse:
        return 'bpm';
      case MeasurementType.temperature:
        return '°C';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case MeasurementType.bloodPressure:
        return Icons.favorite;
      case MeasurementType.bloodSugar:
        return Icons.water_drop;
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.pulse:
        return Icons.heart_broken;
      case MeasurementType.temperature:
        return Icons.thermostat;
    }
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String value;
      if (widget.type == MeasurementType.bloodPressure) {
        value = '${_systolicController.text}/${_diastolicController.text}';
      } else {
        value = _valueController.text;
      }

      final measurement = MeasurementModel(
        type: widget.type,
        value: value,
        unit: _unit,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await _firestoreService.addMeasurement(
        patientUid: widget.patientUid,
        measurement: measurement,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ölçüm kaydedildi!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  size: 32,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              if (widget.type == MeasurementType.bloodPressure) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Sistolik',
                          hintText: '120',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Gerekli';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 50 || num > 250) {
                            return 'Geçersiz';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diyastolik',
                          hintText: '80',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Gerekli';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 30 || num > 150) {
                            return 'Geçersiz';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Değer',
                    hintText: _getHintText(),
                    suffixText: _unit,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir değer girin';
                    }
                    final num = double.tryParse(value);
                    if (num == null) {
                      return 'Geçersiz sayı';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notlar (İsteğe bağlı)',
                  hintText: 'Ek bilgiler...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMeasurement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Kaydet',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (widget.type) {
      case MeasurementType.bloodSugar:
        return '100';
      case MeasurementType.weight:
        return '70';
      case MeasurementType.pulse:
        return '72';
      case MeasurementType.temperature:
        return '36.5';
      default:
        return '';
    }
  }
}
