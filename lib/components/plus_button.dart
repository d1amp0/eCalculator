import 'package:flutter/material.dart';

class PlusButton extends StatelessWidget {
  const PlusButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('add-mark-button'),
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Оценка'),
    );
  }
}
