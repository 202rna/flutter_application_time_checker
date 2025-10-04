import 'package:flutter_application_time_checker/domain/model/timing.dart';

abstract class TimingRepository {
  Future<Timing> getTiming({
    required int id,
  });
}
