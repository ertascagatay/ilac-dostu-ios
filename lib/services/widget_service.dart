import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.med_tracker'; // Use your App Group ID for iOS
  static const String iOSWidgetName = 'MedicationWidget';
  static const String androidWidgetName = 'MedicationWidget';

  static Future<void> updateHomeWidget({String? medName, String? medTime}) async {
    try {
      final name = medName ?? 'İlaç Yok';
      final time = medTime ?? '';

      // Save data
      await HomeWidget.saveWidgetData<String>('medication_name', name);
      await HomeWidget.saveWidgetData<String>('medication_time', time);
      
      // Update widgets
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      print('Widget update failed: $e');
    }
  }
}
