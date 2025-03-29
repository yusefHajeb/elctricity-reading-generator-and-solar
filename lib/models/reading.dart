class Reading {
  final int? id;
  final int? generatorId;
  final int? solarSystemId;
  final double meterReading;
  final double? dieselConsumption;
  final DateTime readingDate;
  final DateTime timestamp;

  Reading({
    this.id,
    this.generatorId,
    this.solarSystemId,
    required this.meterReading,
    this.dieselConsumption,
    required this.readingDate,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now() {
    // Ensure either generatorId or solarSystemId is provided, but not both
    assert((generatorId != null) != (solarSystemId != null),
        'Either generatorId or solarSystemId must be provided, but not both');
    // Ensure dieselConsumption is only provided for generators
    assert(generatorId == null || dieselConsumption != null,
        'Diesel consumption must be provided for generators');
    assert(solarSystemId == null || dieselConsumption == null,
        'Diesel consumption should not be provided for solar systems');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'generator_id': generatorId,
      'solar_system_id': solarSystemId,
      'meter_reading': meterReading,
      'diesel_consumption': dieselConsumption,
      'reading_date': readingDate.toIso8601String().split('T')[0],
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Calculate diesel consumption rate (L/kW)

  double? getDieselConsumptionRate() {
    if (generatorId != null && dieselConsumption != null && meterReading > 0) {
      return dieselConsumption! / meterReading;
    }
    return null;
  }

  factory Reading.fromMap(Map<String, dynamic> map) {
    return Reading(
      id: map['id'],
      generatorId: map['generator_id'],
      solarSystemId: map['solar_system_id'],
      meterReading: map['meter_reading'],
      dieselConsumption: map['diesel_consumption'],
      readingDate: DateTime.parse(map['reading_date']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Reading copyWith({
    int? id,
    int? generatorId,
    int? solarSystemId,
    double? meterReading,
    double? dieselConsumption,
    DateTime? readingDate,
    DateTime? timestamp,
  }) {
    return Reading(
      id: id ?? this.id,
      generatorId: generatorId ?? this.generatorId,
      solarSystemId: solarSystemId ?? this.solarSystemId,
      meterReading: meterReading ?? this.meterReading,
      dieselConsumption: dieselConsumption ?? this.dieselConsumption,
      readingDate: readingDate ?? this.readingDate,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
