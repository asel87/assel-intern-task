import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/theme_switcher.dart';
import 'stock_page.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/stock_service.dart';
import '../widgets/product_card.dart';
import '../widgets/confirmation_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService _service = ProductService();
  final StockService _stockService = StockService();

  // Прокрутка и якорь
  final _scrollController = ScrollController();
  final _topAnchorKey = GlobalKey();

  // Поля формы (товар)
  final _nameController = TextEditingController();
  final _gtinController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _imagePath;

  final _warehouseCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  // key-value характеристики
  final List<MapEntry<TextEditingController, TextEditingController>>
      _specCtrls = [];

  // Поиск/сортировка/фильтр
  final _searchController = TextEditingController();
  String _sort = 'date';
  String _uiCategoryFilter = 'Все';

  bool _ready = false;

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    await _service.init();
    await _stockService.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _gtinController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _warehouseCtrl.dispose();
    _qtyCtrl.dispose();
    for (final e in _specCtrls) {
      e.key.dispose();
      e.value.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || !_service.box.isOpen) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              onTapAdd: () {
                _unfocus();
                _showAddEditSheet();
              },
              onCategorySelected: (value) =>
                  setState(() => _uiCategoryFilter = value),
              selected: _uiCategoryFilter,
            ),
          ),

          // Поиск + сортировка
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск (назв/GTIN/описание/теги)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Очистить',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _unfocus();
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Сортировка',
                        icon: const Icon(Icons.sort),
                        onSelected: (v) => setState(() => _sort = v),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'date', child: Text('По дате')),
                          PopupMenuItem(
                              value: 'modified', child: Text('По изменению')),
                          PopupMenuItem(
                              value: 'name', child: Text('По названию')),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(key: _topAnchorKey, height: 0)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            sliver: _buildListSliver(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _unfocus();
          _showAddEditSheet();
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StockPage()),
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

  // ---------- СПИСОК ----------
  SliverList _buildListSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, __) {
          return ValueListenableBuilder<Box>(
            valueListenable: _service.box.listenable(),
            builder: (context, box, _) {
              final q = _searchController.text.trim();
              var entries =
                  q.isEmpty ? _service.getAllEntries() : _service.search(q);

              // Сортировка
              entries.sort((a, b) {
                if (_sort == 'name') {
                  return a.value.name
                      .toLowerCase()
                      .compareTo(b.value.name.toLowerCase());
                } else if (_sort == 'modified') {
                  final ad = a.value.lastModified ?? a.value.createdAt;
                  final bd = b.value.lastModified ?? b.value.createdAt;
                  return bd.compareTo(ad);
                } else {
                  return b.value.createdAt.compareTo(a.value.createdAt);
                }
              });

              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Нет добавленных товаров')),
                );
              }

              return Column(
                children: [
                  for (final item in entries) ...[
                    ProductCard(
                      key: ValueKey(item.key),
                      product: item.value,
                      onEdit: () {
                        _unfocus();
                        _showAddEditSheet(
                            editKey: item.key, existing: item.value);
                      },
                      onDelete: () async {
                        _unfocus();
                        final ok = await showConfirmDialog(
                          context,
                          title: 'Удалить товар?',
                          message: 'Запись будет удалена.',
                        );
                        if (ok == true) {
                          await _service.delete(item.key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 18),
                                    SizedBox(width: 8),
                                    Text('Товар удалён'),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
        childCount: 1,
      ),
    );
  }

  Future<void> _scrollToListTop() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final ctx = _topAnchorKey.currentContext;
    if (ctx != null) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
        return;
      } catch (_) {}
    }
    try {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  // ==== Bottom Sheet ====
  Future<void> _showAddEditSheet({dynamic editKey, Product? existing}) async {
    _unfocus();

    // заполнение полей
    if (existing != null) {
      _nameController.text = existing.name;
      _gtinController.text = existing.gtin;
      _priceController.text = existing.price.toStringAsFixed(0);
      _descController.text = existing.description ?? '';
      _tagsController.text = (existing.tags ?? []).join(', ');
      _imagePath = existing.imagePath;
      _specCtrls
        ..clear()
        ..addAll(
          (existing.specs ?? {}).entries.map(
                (e) => MapEntry(
                  TextEditingController(text: e.key),
                  TextEditingController(text: e.value),
                ),
              ),
        );
      _warehouseCtrl.clear();
      _qtyCtrl.text = '1';
    } else {
      _nameController.clear();
      _gtinController.clear();
      _priceController.clear();
      _descController.clear();
      _tagsController.clear();
      _imagePath = null;
      _specCtrls.clear();
      _warehouseCtrl.text = '';
      _qtyCtrl.text = '1';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final maxH = MediaQuery.of(ctx).size.height * 0.9;

        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 10),

                // Заголовок
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        existing == null
                            ? 'Добавить товар'
                            : 'Редактировать товар',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge!
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Закрыть',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Форма (скролл)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Theme(
                      data: Theme.of(ctx).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: cs.surfaceVariant.withOpacity(.35),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration:
                                const InputDecoration(labelText: 'Название'),
                          ),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final isEditingExisting = existing != null;
                              return TextFormField(
                                controller: _gtinController,
                                keyboardType: TextInputType.number,
                                readOnly: isEditingExisting,
                                canRequestFocus: !isEditingExisting,
                                enableInteractiveSelection: !isEditingExisting,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(13),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'GTIN (13 цифр)',
                                  suffixIcon: isEditingExisting
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(Icons.lock_outline),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _priceController,
                            decoration:
                                const InputDecoration(labelText: 'Цена'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'))
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Описание',
                              helperText: 'Материалы, размер, особенности',
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Теги
                          TextFormField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                                labelText: 'Теги (через запятую)'),
                          ),
                          const SizedBox(height: 16),

                          // Характеристики
                          Row(
                            children: [
                              Text(
                                'Характеристики',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                onPressed: () => setState(() => _specCtrls.add(
                                      MapEntry(TextEditingController(),
                                          TextEditingController()),
                                    )),
                                icon: const Icon(Icons.add),
                                tooltip: 'Добавить характеристику',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (int i = 0; i < _specCtrls.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _specCtrls[i].key,
                                      decoration: const InputDecoration(
                                          hintText: 'Ключ (напр. Материал)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _specCtrls[i].value,
                                      decoration: const InputDecoration(
                                          hintText: 'Значение (напр. PU)'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () =>
                                        setState(() => _specCtrls.removeAt(i)),
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Удалить',
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),

                          if (_imagePath != null &&
                              File(_imagePath!).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(File(_imagePath!),
                                  height: 140, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                _unfocus();

                                final picked = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  final appDir =
                                      await getApplicationDocumentsDirectory();
                                  final imagesDir =
                                      Directory('${appDir.path}/images');
                                  if (!await imagesDir.exists()) {
                                    await imagesDir.create(recursive: true);
                                  }

                                  final fileName =
                                      '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                  final savedImage = await File(picked.path)
                                      .copy('${imagesDir.path}/$fileName');

                                  setState(() => _imagePath = savedImage.path);
                                }
                                // ===========================================================
                              },
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Добавить изображение'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),

                          if (existing == null) ...[
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Начальные остатки',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _warehouseCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Склад',
                                hintText: 'например, Центральный',
                                prefixIcon: Icon(Icons.home_work_outlined),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Количество',
                                prefixIcon: Icon(Icons.numbers),
                                helperText:
                                    'Будет создана запись в «Остатках».',
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // Кнопки
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 14,
                        offset: const Offset(0, -2),
                      ),
                    ],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            _unfocus();

                            if (_nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Введите название')));
                              return;
                            }
                            if (!_service
                                .validateGTIN(_gtinController.text.trim())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                      'GTIN должен быть корректным EAN-13'),
                                ),
                              );
                              return;
                            }
                            final parsedPrice = double.tryParse(
                                _priceController.text.replaceAll(',', '.'));
                            if (parsedPrice == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('Цена должна быть числом'),
                                ),
                              );
                              return;
                            }

                            String? warehouse;
                            int? qty;
                            if (existing == null) {
                              warehouse = _warehouseCtrl.text.trim();
                              if (warehouse.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Укажите склад'),
                                  ),
                                );
                                return;
                              }
                              qty = int.tryParse(_qtyCtrl.text.trim());
                              if (qty == null || qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Количество должно быть > 0'),
                                  ),
                                );
                                return;
                              }
                            }

                            final specs = {
                              for (final e in _specCtrls)
                                if (e.key.text.trim().isNotEmpty)
                                  e.key.text.trim(): e.value.text.trim(),
                            };
                            final tags = _tagsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            if (existing == null) {
                              final product = Product(
                                name: _nameController.text.trim(),
                                gtin: _gtinController.text.trim(),
                                price: parsedPrice,
                                createdAt: DateTime.now(),
                                imagePath: _imagePath,
                                description: _descController.text.trim().isEmpty
                                    ? null
                                    : _descController.text.trim(),
                                // category: null  // категорию убрали
                                tags: tags.isEmpty ? null : tags,
                                specs: specs.isEmpty ? null : specs,
                              );
                              await _service.addProduct(product);
                              await _stockService.addOrIncrease(
                                warehouse: warehouse!,
                                gtin: product.gtin,
                                qty: qty!,
                              );
                            } else {
                              final updated = existing.copyWith(
                                name: _nameController.text.trim(),
                                price: parsedPrice,
                                imagePath: _imagePath,
                                description: _descController.text.trim().isEmpty
                                    ? null
                                    : _descController.text.trim(),
                                // category: null
                                tags: tags.isEmpty ? null : tags,
                                specs: specs.isEmpty ? null : specs,
                              );
                              await _service.editProduct(editKey, updated);
                            }

                            if (mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 18),
                                      const SizedBox(width: 8),
                                      Text(existing == null
                                          ? 'Товар сохранён и добавлен в «Остатки»'
                                          : 'Товар обновлён'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            await _scrollToListTop();
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onTapAdd;
  final String selected;
  final ValueChanged<String> onCategorySelected;

  const _HeroHeader({
    required this.onTapAdd,
    required this.onCategorySelected,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(.95), cs.primary.withOpacity(.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              ThemeSwitcherAction(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Volleyball\nCollection',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: cs.onPrimary,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 10),
          ChipTheme(
            data: ChipTheme.of(context).copyWith(
              shape: const StadiumBorder(),
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: Colors.white,
              selectedColor: cs.secondaryContainer,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: -6,
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: selected == 'Все',
                  onSelected: (_) => onCategorySelected('Все'),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected == 'Все'
                        ? cs.onSecondaryContainer
                        : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
