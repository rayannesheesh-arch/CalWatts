/// Enum representing the different types of household appliances.
enum ApplianceCategory {
  fan,
  light,
  television,
  refrigerator,
  riceCooker,
  airConditioner;

  /// Convert enum to string representation for serialization.
  String toJson() => name;

  /// Create enum from string representation.
  static ApplianceCategory fromJson(String json) =>
      ApplianceCategory.values.firstWhere(
        (e) => e.name == json,
        orElse: () => ApplianceCategory.fan,
      );
}
