class SolarSystemsReading {
  final int? id;
  final int solarSystemId;
  final double meterReading;
  final DateTime timestamp;

  SolarSystemsReading({
    this.id,
    required this.solarSystemId,
    required this.meterReading,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'solar_system_id': solarSystemId,
      'meter_reading': meterReading,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SolarSystemsReading.fromMap(Map<String, dynamic> map) {
    return SolarSystemsReading(
      id: map['id'],
      solarSystemId: map['solar_system_id'],
      meterReading: map['meter_reading'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
