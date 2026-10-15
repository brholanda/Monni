import 'package:flutter/material.dart';

/// Título de diálogo/modal com botão de fecho.
class DialogHeader extends StatelessWidget {
  const DialogHeader({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
