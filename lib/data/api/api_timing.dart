class ApiTiming {
  final int id;
  final Duration timing;
  final DateTime dateTimeFrom;
  final DateTime dateTimeTo;
  ApiTiming.fromApi(Map<String, dynamic> map)
      : id = map['result']['id'],
        timing = map['result']['timing'],
        dateTimeFrom = map['result']['dateTimeFrom'],
        dateTimeTo = map['result']['dateTimeTo'];
}
