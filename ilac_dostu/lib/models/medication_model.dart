import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeOfDayType { morning, evening }

enum HungerStatus { empty, full, neutral }

enum MedicationFrequency {
  everyday,        // Günde 1 kez (Her gün)
  twiceDaily,      // Günde 2 kez
  threeTimesDaily, // Günde 3 kez
  fourTimesDaily,  // Günde 4 kez
  everyOtherDay,   // Gün aşırı (2 günde bir)
  weekly,          // Haftada 1 kez
  twiceWeekly,     // Haftada 2 kez
  monthly,         // Ayda 1 kez
  asNeeded,        // İhtiyaç halinde
}

class MedicationModel {
  final String? id;
  final String name;
  final String time;
  final TimeOfDayType timeOfDay;
  final bool isTaken;
  final String? imagePath;
  final int stockCount;
  final HungerStatus hungerStatus;
  final MedicationFrequency frequency;
  final DateTime createdAt;
  final DateTime? caregiverAlertTime;

  MedicationModel({
    this.id,
    required this.name,
    required this.time,
    required this.timeOfDay,
    this.isTaken = false,
    this.imagePath,
    this.stockCount = 30,
    this.hungerStatus = HungerStatus.neutral,
    this.frequency = MedicationFrequency.everyday,
    this.caregiverAlertTime,
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
      'frequency': frequency.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'caregiverAlertTime': caregiverAlertTime != null
          ? Timestamp.fromDate(caregiverAlertTime!)
          : null,
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

  static MedicationFrequency _stringToFrequency(String? freq) {
    switch (freq) {
      case 'twiceDaily':
        return MedicationFrequency.twiceDaily;
      case 'threeTimesDaily':
        return MedicationFrequency.threeTimesDaily;
      case 'fourTimesDaily':
        return MedicationFrequency.fourTimesDaily;
      case 'everyOtherDay':
        return MedicationFrequency.everyOtherDay;
      case 'weekly':
        return MedicationFrequency.weekly;
      case 'twiceWeekly':
        return MedicationFrequency.twiceWeekly;
      case 'monthly':
        return MedicationFrequency.monthly;
      case 'asNeeded':
        return MedicationFrequency.asNeeded;
      case 'everyday':
      default:
        return MedicationFrequency.everyday;
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
      frequency: _stringToFrequency(map['frequency'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      caregiverAlertTime:
          (map['caregiverAlertTime'] as Timestamp?)?.toDate(),
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
    MedicationFrequency? frequency,
    DateTime? caregiverAlertTime,
    bool clearAlertTime = false,
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
      frequency: frequency ?? this.frequency,
      caregiverAlertTime:
          clearAlertTime ? null : (caregiverAlertTime ?? this.caregiverAlertTime),
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

  String get frequencyDisplay {
    switch (frequency) {
      case MedicationFrequency.everyday:
        return 'Günde 1 kez (Her gün)';
      case MedicationFrequency.twiceDaily:
        return 'Günde 2 kez';
      case MedicationFrequency.threeTimesDaily:
        return 'Günde 3 kez';
      case MedicationFrequency.fourTimesDaily:
        return 'Günde 4 kez';
      case MedicationFrequency.everyOtherDay:
        return 'Gün aşırı (2 günde bir)';
      case MedicationFrequency.weekly:
        return 'Haftada 1 kez';
      case MedicationFrequency.twiceWeekly:
        return 'Haftada 2 kez';
      case MedicationFrequency.monthly:
        return 'Ayda 1 kez';
      case MedicationFrequency.asNeeded:
        return 'İhtiyaç halinde';
    }
  }
}
