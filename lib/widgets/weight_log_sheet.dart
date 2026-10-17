import 'package:flutter/material.dart';

import 'glass.dart';

/// Shows a lightweight dialog and returns the entered weight if it was saved.
/// This deliberately avoids the custom modal bottom-sheet route: on some older
/// Flutter engines its keyboard-back dismissal can trigger an inherited-widget
/// deactivation assertion.
Future<double?> showWeightLogSheet(
  BuildContext context, {
  required DateTime date,
  required double initialKg,
  bool hasExistingEntry = false,
}) {
  final controller = TextEditingController(text: initialKg.toStringAsFixed(1));
  return showDialog<double>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: C.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(children: [
        Icon(Icons.monitor_weight_outlined, color: C.mint),
        const SizedBox(width: 10),
        Text(hasExistingEntry ? 'Update weight' : 'Log today\'s weight',
            style: t(20, w: FontWeight.w800)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${date.day}/${date.month}/${date.year}',
            style: t(13, color: C.textDim)),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: t(30, w: FontWeight.w800),
          decoration: InputDecoration(
            suffixText: 'kg',
            suffixStyle: t(15, color: C.textDim),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            final kg = double.tryParse(value.trim());
            if (kg != null && kg >= 20 && kg <= 300) {
              Navigator.pop(dialogContext, kg);
            }
          },
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final kg = double.tryParse(controller.text.trim());
            if (kg == null || kg < 20 || kg > 300) return;
            Navigator.pop(dialogContext, kg);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save weight'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
