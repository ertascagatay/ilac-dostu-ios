import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeOfDayType { morning, evening }

enum HungerStatus { empty, full, neutral }

class MedicationModel {
  final String? id;
  final String name;
  final String time;
  final TimeOfDayType timeOfDay;
  final bool isTaken;
  final String? imagePath;
  final int stockCount;
  final HungerStatus hungerStatus;
  final DateTime createdAt;

  MedicationModel({
    this.id,
    required this.name,
    required this.time,
    required this.timeOfDay,
    this.isTaken = false,
    this.imagePath,
    this.stockCount = 30,
    this.hungerStatus = HungerStatus.neutral,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'timeOfDay': timeOfDay == TimeOfDayType.morning ? 'morning' : 'evening',
      'isTaken': isTaken,
      'imagePath': imagePath,
      'stockCount': stockCount,
      'hungerStatus': hungerStatus.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static HungerStatus _stringToHungerStatus(String? status) {
    switch (status) {
      case 'empty':
        return HungerStatus.empty;
      case 'full':
        return HungerStatus.full;
      default:
        return HungerStatus.neutral;
    }
  }

  factory MedicationModel.fromMap(String id, Map<String, dynamic> map) {
    return MedicationModel(
      id: id,
      name: map['name'] as String,
      time: map['time'] as String,
      timeOfDay: map['timeOfDay'] == 'morning' 
          ? TimeOfDayType.morning 
          : TimeOfDayType.evening,
      isTaken: map['isTaken'] as bool? ?? false,
      imagePath: map['imagePath'] as String?,
      stockCount: map['stockCount'] as int? ?? 30,
      hungerStatus: _stringToHungerStatus(map['hungerStatus'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MedicationModel copyWith({
    String? id,
    String? name,
    String? time,
    TimeOfDayType? timeOfDay,
    bool? isTaken,
    String? imagePath,
    int? stockCount,
    HungerStatus? hungerStatus,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isTaken: isTaken ?? this.isTaken,
      imagePath: imagePath ?? this.imagePath,
      stockCount: stockCount ?? this.stockCount,
      hungerStatus: hungerStatus ?? this.hungerStatus,
      createdAt: createdAt,
    );
  }

  String get hungerStatusDisplay {
    switch (hungerStatus) {
      case HungerStatus.empty:
        return 'Aç';
      case HungerStatus.full:
        return 'Tok';
      case HungerStatus.neutral:
        return '';
    }
  }
}
