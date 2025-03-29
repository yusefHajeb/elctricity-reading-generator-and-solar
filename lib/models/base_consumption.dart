// ignore_for_file: public_member_api_docs, sort_constructors_first
abstract class BaseConsumption {
  final double startReading;
  final double endReading;
  final double totalConsumption;
  final int readingCount;
  final String generatorName;

  const BaseConsumption({
    required this.startReading,
    required this.endReading,
    required this.totalConsumption,
    required this.readingCount,
    required this.generatorName,
  });
}

class GeneratorConsumption extends BaseConsumption {
  final int generatorId;
  final double totalDiesel;
  final double efficiency;

  const GeneratorConsumption({
    required this.generatorId,
    required super.generatorName,
    required super.startReading,
    required super.endReading,
    required super.totalConsumption,
    required this.totalDiesel,
    required this.efficiency,
    required super.readingCount,
  });
}

class SolarConsumption extends BaseConsumption {
  final int solarSystemId;
  final String solarSystemName;

  SolarConsumption({
    required super.startReading,
    required super.endReading,
    required super.totalConsumption,
    required super.readingCount,
    required this.solarSystemId,
    required this.solarSystemName,
  }) : super(
          generatorName: solarSystemName,
        );
}
