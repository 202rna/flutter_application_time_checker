import 'package:flutter_application_time_checker/domain/model/timing.dart';

abstract class GroupRepository {
  Future<Timing> getGroup({
    required int id,
  });
}
