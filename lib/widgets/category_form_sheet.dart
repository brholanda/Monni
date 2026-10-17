import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import 'dialog_header.dart';

class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({
    super.key,
    required this.isDuplicate,
    required this.suggestedColor,
    this.initial,
  });

  final bool Function(String name) isDuplicate;
  final Color suggestedColor;
  final ExpenseCategory? initial;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.initial?.name ?? '');

  late Color _color = widget.initial?.color ?? widget.suggestedColor;
  late String _iconKey = widget.initial?.iconKey ?? kCategoryIcons.keys.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExpenseCategory(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        color: _color,
        enabled: widget.initial?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconKeys = kCategoryIcons.keys.toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogHeader(
              title: widget.initial == null
                  ? 'Nova categoria'
                  : 'Editar categoria',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Nome',
                counterText: '',
              ),
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.isEmpty) return 'Indique um nome';
                if (widget.isDuplicate(name)) {
                  return 'Já existe uma categoria com esse nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Cor', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in kCategoryPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Ícone', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: iconKeys.length,
                itemBuilder: (context, index) {
                  final key = iconKeys[index];
                  final selected = key == _iconKey;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _iconKey = key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? _color.withValues(alpha: 0.18)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        categoryIconFor(key),
                        color: selected
                            ? _color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? 'Criar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
