/// Represents a single appliance usage entry within a simulation day.
class SimApplianceUsage {
  final String applianceId;
  final double hours;
  final int quantity;

  const SimApplianceUsage({
    required this.applianceId,
    required this.hours,
    this.quantity = 1,
  });

  SimApplianceUsage copyWith({String? applianceId, double? hours, int? quantity}) {
    return SimApplianceUsage(
      applianceId: applianceId ?? this.applianceId,
      hours: hours ?? this.hours,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'applianceId': applianceId,
        'hours': hours,
        'quantity': quantity,
      };

  static SimApplianceUsage fromJson(Map<String, dynamic> json) => SimApplianceUsage(
        applianceId: json['applianceId'] as String,
        hours: (json['hours'] as num).toDouble(),
        quantity: (json['quantity'] as int?) ?? 1,
      );
}

/// Represents the configuration for a single simulation day (1–31).
class SimDay {
  /// Day number (1–31).
  final int day;

  /// List of appliance usages for this day.
  final List<SimApplianceUsage> usages;

  const SimDay({required this.day, required this.usages});

  SimDay copyWith({int? day, List<SimApplianceUsage>? usages}) {
    return SimDay(
      day: day ?? this.day,
      usages: usages ?? this.usages,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'usages': usages.map((u) => u.toJson()).toList(),
      };

  static SimDay fromJson(Map<String, dynamic> json) => SimDay(
        day: json['day'] as int,
        usages: (json['usages'] as List)
            .map((u) => SimApplianceUsage.fromJson(u as Map<String, dynamic>))
            .toList(),
      );
}
