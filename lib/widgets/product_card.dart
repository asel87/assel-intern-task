import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  String _fmtDate(DateTime d) => d.toIso8601String().substring(0, 10);
  String _fmtPrice(double p) {
    final v = p.round();
    return '$v ₸';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        File(product.imagePath!).existsSync();
    final previewDesc = (product.description ?? '').trim();
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // ---------- IMAGE ----------
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(product.imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: !hasImage
                  ? Icon(Icons.sports_volleyball,
                      size: 40, color: cs.outline.withOpacity(0.7))
                  : null,
            ),

            // ---------- DETAILS ----------
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название
                    Text(
                      product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Цена
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _fmtPrice(product.price),
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    // Описание
                    if (previewDesc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        previewDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],

                    // Теги
                    if ((product.tags ?? const []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: product.tags!.take(3).map((t) {
                            return Chip(
                              label: Text(t),
                              labelStyle: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              backgroundColor: cs.secondaryContainer,
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ---------- ACTIONS ----------
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                  const SizedBox(height: 4),
                  IconButton.filledTonal(
                    tooltip: 'Удалить',
                    style: IconButton.styleFrom(
                        backgroundColor: cs.errorContainer),
                    icon: Icon(Icons.delete_outline,
                        color: cs.onErrorContainer, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
