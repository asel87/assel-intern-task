import 'package:hive/hive.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final IProductRepository _repo;
  ProductService({IProductRepository? repo})
      : _repo = repo ?? HiveProductRepository();

  Future<void> init() async => _repo.init();
  Box get box => _repo.box;

  bool validateGTIN(String gtin) => RegExp(r'^\d{13}$').hasMatch(gtin);

  // CREATE
  Future<dynamic> addProduct(Product product) async {
    return _repo.add(product.toMap());
  }

  // UPDATE
  Future<void> editProduct(dynamic key, Product product) async {
    await _repo.put(key, product.toMap());
  }

  // DELETE
  Future<void> delete(dynamic key) async => _repo.delete(key);

  // READ ALL
  List<MapEntry<dynamic, Product>> getAllEntries() {
    final keys = _repo.keys.toList();
    return keys
        .map((k) {
          final raw = _repo.get(k);
          if (raw == null) return null;
          try {
            final p = Product.fromMap(Map<String, dynamic>.from(raw));
            return MapEntry(k, p);
          } catch (_) {
            return null;
          }
        })
        .whereType<MapEntry<dynamic, Product>>()
        .toList();
  }

  List<MapEntry<dynamic, Product>> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllEntries();
    return getAllEntries().where((e) {
      final name = e.value.name.toLowerCase();
      final gtin = e.value.gtin.toLowerCase();
      return name.contains(q) || gtin.contains(q);
    }).toList();
  }
}
