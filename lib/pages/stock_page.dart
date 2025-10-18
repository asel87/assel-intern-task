import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'home_page.dart';
import '../services/stock_service.dart';
import '../models/stock.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final StockService _service = StockService();

  final _warehouseCtrl = TextEditingController();
  final _gtinCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  String? _filterWarehouse;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _warehouseCtrl.dispose();
    _gtinCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;

    final warehouses = _warehouses();
    final currentFilter =
        (_filterWarehouse != null && warehouses.contains(_filterWarehouse))
            ? _filterWarehouse
            : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Остатки')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Card(
              elevation: 0,
              color: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Склад
                      TextFormField(
                        controller: _warehouseCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Склад',
                          hintText: 'например, Центральный',
                          prefixIcon: Icon(Icons.home_work_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Укажи склад'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      // GTIN
                      TextFormField(
                        controller: _gtinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'GTIN (13 цифр)',
                          helperText: 'Штрихкод EAN-13',
                          prefixIcon: Icon(Icons.qr_code_2),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Укажи GTIN';
                          if (s.length != 13) return 'Должно быть 13 цифр';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      // Кол-во + кнопка
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Кол-во',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n <= 0)
                                  return 'Введите число > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _onAddOrIncrease,
                              icon: const Icon(Icons.add),
                              label: Text(_predictButtonLabel()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Фильтр + Итого
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: currentFilter, // безопасное значение
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Все склады'),
                                ),
                                ...warehouses.map(
                                  (w) => DropdownMenuItem<String?>(
                                    value: w,
                                    child: Text(w),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterWarehouse = v),
                              decoration: const InputDecoration(
                                labelText: 'Фильтр по складу',
                                prefixIcon: Icon(Icons.filter_list_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Итого: ${_service.totalQty()}',
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _warehouseChips(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 0),

          // ---------- СПИСОК ----------
          Expanded(
            child: ValueListenableBuilder<Box>(
              valueListenable: _service.box.listenable(),
              builder: (context, box, _) {
                // пересчёт тут, чтобы учесть удаление последнего склада
                final ws = _warehouses();
                final cf =
                    (_filterWarehouse != null && ws.contains(_filterWarehouse))
                        ? _filterWarehouse
                        : null;

                final entries = _service.getAllEntries(byWarehouse: cf);
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('Нет записей. Добавь первый остаток выше.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final s = e.value;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        title: Text(
                          s.warehouse,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('GTIN: ${s.gtin}'),
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          child: Text(
                            'x${s.qty}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Списать со склада',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _showDecreaseSheet(s),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              tooltip: 'Удалить запись',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await _confirmDeleteDialog(
                                  context,
                                  warehouse: s.warehouse,
                                  gtin: s.gtin,
                                );
                                if (ok) await _deleteByKey(e.key);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Товары',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse),
            label: 'Остатки',
          ),
        ],
      ),
    );
  }

  // ---------- ЛОГИКА ----------

  String _predictButtonLabel() {
    final wh = _warehouseCtrl.text.trim();
    final g = _gtinCtrl.text.trim();
    if (wh.isEmpty || g.length != 13) return 'Добавить';
    final exists =
        _service.getAllEntries(byWarehouse: wh).any((e) => e.value.gtin == g);
    return exists ? 'Увеличить' : 'Добавить';
  }

  Future<void> _onAddOrIncrease() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.parse(_qtyCtrl.text);
    final wh = _warehouseCtrl.text.trim();
    final g = _gtinCtrl.text.trim();

    await _service.addOrIncrease(warehouse: wh, gtin: g, qty: qty);
    _qtyCtrl.text = '1';
    setState(() {});
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Остаток сохранён'),
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context,
      {required String warehouse, required String gtin}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Склад: $warehouse\nGTIN: $gtin'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }

  /// Удаление записи по ключу бокса (напрямую через Hive box)
  Future<void> _deleteByKey(dynamic key) async {
    await _service.box.delete(key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Запись удалена'),
      ),
    );
    setState(() {});
  }

  Future<void> _showDecreaseSheet(Stock s) async {
    final controller = TextEditingController(text: '1');

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Списать со склада',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                  'Склад: ${s.warehouse}\nGTIN: ${s.gtin}\nДоступно: ${s.qty}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Списать, шт.',
                        helperText: 'Макс: ${s.qty}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final dec = int.tryParse(controller.text) ?? 0;
                      if (dec <= 0) return;
                      final ok = await _service.decrease(
                        warehouse: s.warehouse,
                        gtin: s.gtin,
                        qty: dec,
                      );
                      if (!mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Нельзя списать больше, чем есть'),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Остаток обновлён'),
                          ),
                        );
                        setState(() {});
                      }
                    },
                    child: const Text('Списать'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- UI HELPERS ----------

  Widget _warehouseChips() {
    final ws = _warehouses();
    if (ws.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: -6,
      children: [
        FilterChip(
          label: const Text('Все'),
          selected: _filterWarehouse == null,
          onSelected: (_) => setState(() => _filterWarehouse = null),
        ),
        ...ws.map(
          (w) => FilterChip(
            label: Text(w),
            selected: _filterWarehouse == w,
            onSelected: (_) => setState(() => _filterWarehouse = w),
          ),
        ),
      ],
    );
  }

  List<String> _warehouses() {
    final entries = _service.getAllEntries();
    final set = <String>{};
    for (final e in entries) {
      set.add(e.value.warehouse);
    }
    final list = set.toList()..sort();
    return list;
  }
}
