import 'package:flutter/material.dart';

/// Lipo de dialogue de création ou de modification d'un groupe.
/// Retourne le nom saisi via [Navigator.pop], ou `null` en cas
/// d'annulation.
class AddEditGroupDialog extends StatefulWidget {
  final String? initialName;

  const AddEditGroupDialog({super.key, this.initialName});

  @override
  State<AddEditGroupDialog> createState() => _AddEditGroupDialogState();
}

class _AddEditGroupDialogState extends State<AddEditGroupDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est obligatoire.';
    }
    if (value.trim().length > 40) {
      return 'Le nom doit faire moins de 40 caractères.';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop<String>(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialName != null;
    return AlertDialog(
      title: Text(isEditing ? 'Renommer le groupe' : 'Nouveau groupe'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom du groupe'),
          validator: _validateName,
          onFieldSubmitted: (String _) => _submit(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}
