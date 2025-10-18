import 'package:hive/hive.dart';
import '../models/stock.dart';
import '../repositories/stock_repository.dart';

class StockService {
  final IStockRepository _repo;
  StockService({IStockRepository? repo})
      : _repo = repo ?? HiveStockRepository();

  Future<void> init() async => _repo.init();
  Box get box => _repo.box;

  // Добавить или увеличить количество
  Future<void> addOrIncrease({
    required String warehouse,
    required String gtin,
    required int qty,
  }) async {
    final list = getAllEntries();

    // Ищем существующую запись безопасно
    final matches = list
        .where((e) => e.value.gtin == gtin && e.value.warehouse == warehouse)
        .toList();
    final MapEntry<dynamic, Stock>? found =
        matches.isNotEmpty ? matches.first : null;

    if (found != null) {
      final newQty = found.value.qty + qty;
      await _repo.put(found.key, found.value.copyWith(qty: newQty).toMap());
    } else {
      await _repo
          .add(Stock(warehouse: warehouse, gtin: gtin, qty: qty).toMap());
    }
  }

  // Уменьшить количество (с валидацией)
  Future<bool> decrease({
    required String warehouse,
    required String gtin,
    required int qty,
  }) async {
    final list = getAllEntries();

    final matches = list
        .where((e) => e.value.gtin == gtin && e.value.warehouse == warehouse)
        .toList();
    final MapEntry<dynamic, Stock>? found =
        matches.isNotEmpty ? matches.first : null;

    if (found == null) return false;
    if (qty > found.value.qty) return false;

    final newQty = found.value.qty - qty;
    if (newQty == 0) {
      await _repo.delete(found.key);
    } else {
      await _repo.put(found.key, found.value.copyWith(qty: newQty).toMap());
    }
    return true;
  }

  // Получить все
  List<MapEntry<dynamic, Stock>> getAllEntries({String? byWarehouse}) {
    final keys = _repo.keys.toList();
    return keys
        .map((k) {
          final v = _repo.get(k);
          if (v == null) return null;
          final s = Stock.fromMap(Map<String, dynamic>.from(v));
          if (byWarehouse != null && s.warehouse != byWarehouse) return null;
          return MapEntry(k, s);
        })
        .whereType<MapEntry<dynamic, Stock>>()
        .toList();
  }

  // Суммарное кол-во
  int totalQty({String? gtin}) {
    final all = getAllEntries();
    return all
        .where((e) => gtin == null || e.value.gtin == gtin)
        .fold(0, (sum, e) => sum + e.value.qty);
  }
}
