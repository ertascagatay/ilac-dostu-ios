import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeOfDayType { morning, evening }

class MedicationModel {
  final String? id;
  final String name;
  final String time;
  final TimeOfDayType timeOfDay;
  final bool isTaken;
  final String? imagePath;
  final int stockCount;
  final DateTime createdAt;

  MedicationModel({
    this.id,
    required this.name,
    required this.time,
    required this.timeOfDay,
    this.isTaken = false,
    this.imagePath,
    this.stockCount = 30,
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
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
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isTaken: isTaken ?? this.isTaken,
      imagePath: imagePath ?? this.imagePath,
      stockCount: stockCount ?? this.stockCount,
      createdAt: createdAt,
    );
  }
}
