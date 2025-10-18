import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  String title = 'Подтверждение',
  String message = 'Вы уверены?',
}) {
  final cs = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: cs.outline,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ок'),
        ),
      ],
    ),
  );
}
