import 'package:flutter_application_time_checker/domain/model/timing.dart';

abstract class UnitRepository {
  Future<Timing> getUnit({
    required int id,
  });
}
