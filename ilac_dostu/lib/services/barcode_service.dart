class BarcodeService {
  // Mock Turkish medication barcode database
  static const Map<String, String> _medicationDatabase = {
    '8690000000001': 'Aspirin 100mg',
    '8690000000002': 'Parol 500mg',
    '8690000000003': 'Majezik 25mg',
    '8690000000004': 'Coraspin 100mg',
    '8690000000005': 'Demir Tablet',
    '8690000000006': 'Vitamin D3 1000 IU',
    '8690000000007': 'Omega 3 Balık Yağı',
    '8690000000008': 'Kalsiyum + D3',
    '8690000000009': 'Magnezyum 250mg',
    '8690000000010': 'B12 Vitamini',
    '8690000000011': 'Folik Asit 5mg',
    '8690000000012': 'Probiyotik Kapsül',
    '8690000000013': 'Çinko 15mg',
    '8690000000014': 'C Vitamini 1000mg',
    '8690000000015': 'Multivitamin',
  };

  /// Looks up a medication name by barcode
  /// Returns the medication name if found, or null if not found
  static String? lookupMedication(String barcode) {
    return _medicationDatabase[barcode];
  }

  /// Checks if a barcode exists in the database
  static bool isValidBarcode(String barcode) {
    return _medicationDatabase.containsKey(barcode);
  }

  /// Gets all available barcodes (for testing purposes)
  static List<String> getAllBarcodes() {
    return _medicationDatabase.keys.toList();
  }

  /// Gets all medications (for testing purposes)
  static Map<String, String> getAllMedications() {
    return Map.from(_medicationDatabase);
  }
}
