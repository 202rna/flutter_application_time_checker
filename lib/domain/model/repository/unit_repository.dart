import 'package:flutter_application_time_checker/domain/model/unit.dart';

abstract class UnitRepository {
  Future<Unit> getUnit({
    required int id,
  });
}
