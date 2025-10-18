import 'package:hive/hive.dart';

abstract class IProductRepository {
  Future<void> init();
  Box get box;
  Future<dynamic> add(Map<String, dynamic> data);
  Future<void> put(dynamic key, Map<String, dynamic> data);
  Future<void> delete(dynamic key);
  Iterable get keys;
  dynamic get(dynamic key);
  Iterable get values;
}

class HiveProductRepository implements IProductRepository {
  late Box _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox('products_box');
  }

  @override
  Box get box => _box;

  @override
  Future add(Map<String, dynamic> data) => _box.add(data);

  @override
  Future<void> put(key, Map<String, dynamic> data) => _box.put(key, data);

  @override
  Future<void> delete(key) => _box.delete(key);

  @override
  Iterable get keys => _box.keys;

  @override
  dynamic get(key) => _box.get(key);

  @override
  Iterable get values => _box.values;
}
