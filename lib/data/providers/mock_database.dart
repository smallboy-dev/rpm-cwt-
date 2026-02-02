import 'package:get_storage/get_storage.dart';

class MockDatabase {
  final _storage = GetStorage();

  static const String keyUsers = 'users';
  static const String keyProjects = 'projects';
  static const String keyBids = 'bids';
  static const String keyMessages = 'chat_messages';
  static const String keyFiles = 'project_files';
  static const String keyActivity = 'project_activity';
  static const String keyCurrentUser = 'current_user';

  void saveData(String key, dynamic data) => _storage.write(key, data);
  dynamic getData(String key) => _storage.read(key);

  List<T> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    var stored = _storage.read(key);
    if (stored == null) return [];
    if (stored is! List) return [];
    return stored.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }

  void saveList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) {
    _storage.write(key, list.map((e) => toJson(e)).toList());
  }

  void appendToList<T>(
    String key,
    T item,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<T> current = getList<T>(key, fromJson);
    current.add(item);
    saveList<T>(key, current, toJson);
  }
}
