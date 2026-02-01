import 'package:cloud_firestore/cloud_firestore.dart';

enum MeasurementType {
  bloodPressure,
  bloodSugar,
  weight,
  pulse,
  temperature,
}

class MeasurementModel {
  final String? id;
  final MeasurementType type;
  final String value; // e.g., "120/80", "95", "70", "72", "36.5"
  final String unit; // e.g., "mmHg", "mg/dL", "kg", "bpm", "°C"
  final DateTime timestamp;
  final String? notes;

  MeasurementModel({
    this.id,
    required this.type,
    required this.value,
    required this.unit,
    DateTime? timestamp,
    this.notes,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'value': value,
      'unit': unit,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory MeasurementModel.fromMap(String id, Map<String, dynamic> map) {
    return MeasurementModel(
      id: id,
      type: _stringToMeasurementType(map['type'] as String),
      value: map['value'] as String,
      unit: map['unit'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
    );
  }

  static MeasurementType _stringToMeasurementType(String typeString) {
    switch (typeString) {
      case 'bloodPressure':
        return MeasurementType.bloodPressure;
      case 'bloodSugar':
        return MeasurementType.bloodSugar;
      case 'weight':
        return MeasurementType.weight;
      case 'pulse':
        return MeasurementType.pulse;
      case 'temperature':
        return MeasurementType.temperature;
      default:
        return MeasurementType.bloodPressure;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case MeasurementType.bloodPressure:
        return 'Tansiyon';
      case MeasurementType.bloodSugar:
        return 'Kan Şekeri';
      case MeasurementType.weight:
        return 'Kilo';
      case MeasurementType.pulse:
        return 'Nabız';
      case MeasurementType.temperature:
        return 'Ateş';
    }
  }

  String get displayValue => '$value $unit';
}
