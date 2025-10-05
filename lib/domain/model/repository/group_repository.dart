import 'package:flutter_application_time_checker/domain/model/group.dart';

abstract class GroupRepository {
  Future<Group> getGroup({
    required int id,
  });
}
