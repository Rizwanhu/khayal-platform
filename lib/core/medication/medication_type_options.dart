/// UI labels and Supabase `med_type` enum values (tablet, capsule, syrup, …).
abstract final class MedicationTypeOptions {
  static const List<String> uiLabels = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Drops',
    'Injection',
    'Other',
  ];

  /// Maps dropdown label → database enum value.
  static String toDatabaseValue(String uiLabel) {
    switch (uiLabel.trim().toLowerCase()) {
      case 'tablet':
        return 'tablet';
      case 'capsule':
        return 'capsule';
      case 'syrup':
      case 'liquid':
        return 'syrup';
      case 'drops':
        return 'drops';
      case 'injection':
        return 'injection';
      case 'other':
        return 'other';
      default:
        return 'tablet';
    }
  }

  /// Maps database value → dropdown label.
  static String toUiLabel(String? dbValue) {
    switch ((dbValue ?? 'tablet').trim().toLowerCase()) {
      case 'tablet':
        return 'Tablet';
      case 'capsule':
        return 'Capsule';
      case 'syrup':
      case 'liquid':
        return 'Syrup';
      case 'drops':
        return 'Drops';
      case 'injection':
        return 'Injection';
      case 'other':
        return 'Other';
      default:
        return 'Tablet';
    }
  }
}
