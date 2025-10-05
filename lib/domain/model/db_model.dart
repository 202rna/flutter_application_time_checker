abstract class DbModel<T> {
  final T id;
  DbModel({required this.id});

  // Используем при получении данных из базы
  static fromMap(Map<String, dynamic> map) {}
  // Используем при отправке данных в базы
  Map<String, dynamic> toMap() => Map.fromIterable([]);
}
