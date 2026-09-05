import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/box/box_bloc.dart';
import '../blocs/box/box_event.dart';
import '../blocs/group/group_bloc.dart';
import '../blocs/group/group_state.dart';
import '../models/box_color_type.dart';
import '../models/box_group_model.dart';
import '../models/box_model.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/group_selector_field.dart';

class AddEditBoxScreen extends StatefulWidget {
  final BoxModel? existingBox;

  const AddEditBoxScreen({super.key, this.existingBox});

  @override
  State<AddEditBoxScreen> createState() => _AddEditBoxScreenState();
}

class _AddEditBoxScreenState extends State<AddEditBoxScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _daysController;
  late final TextEditingController _hoursController;
  late IconData _selectedIcon;
  late BoxColorType _selectedColor;
  String? _selectedGroupId;

  bool get _isEditing => widget.existingBox != null;

  @override
  void initState() {
    super.initState();
    final BoxModel? box = widget.existingBox;
    _nameController = TextEditingController(text: box?.name ?? '');
    _selectedIcon = box?.icon ?? Icons.inbox;
    _selectedColor = box?.color ?? BoxColorType.yellow;
    _selectedGroupId = box?.groupId;

    // Initialisation des champs de durée
    if (box != null) {
      final Duration remaining = box.remaining();
      final Duration absolute =
          remaining.isNegative ? Duration.zero : remaining;
      _daysController = TextEditingController(text: absolute.inDays.toString());
      _hoursController = TextEditingController(
        text: (absolute.inHours % 24).toString(),
      );
    } else {
      // Valeurs par défaut pour une nouvelle lipo (ex: 7 jours, 0 heure)
      _daysController = TextEditingController(text: '7');
      _hoursController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
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

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Obligatoire';
    }
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Invalide';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int days = int.tryParse(_daysController.text.trim()) ?? 0;
    final int hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final Duration customDuration = Duration(days: days, hours: hours);

    // Sécurité : la durée totale doit être d'au moins 1 minute
    if (customDuration.inMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La durée d\'expiration doit être supérieure à 0.'),
        ),
      );
      return;
    }

    final BoxModel? existingBox = widget.existingBox;
    final BoxBloc boxBloc = context.read<BoxBloc>();

    if (existingBox == null) {
      boxBloc.add(
        AddBoxRequested(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          groupId: _selectedGroupId,
          customDuration: customDuration,
        ),
      );
    } else {
      boxBloc.add(
        UpdateBoxRequested(
          boxId: existingBox.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          groupId: _selectedGroupId,
          clearGroup: _selectedGroupId == null,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la lipo' : 'Nouvelle lipo'),
      ),
      body: BlocBuilder<GroupBloc, GroupState>(
        builder: (BuildContext context, GroupState groupState) {
          final List<BoxGroupModel> groups = groupState is GroupLoaded
              ? groupState.groups
              : groupState is GroupError
                  ? groupState.previousGroups
                  : const <BoxGroupModel>[];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la lipo',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 24),

                // Section de saisie manuelle de la durée
                Text(
                  'Délai avant expiration',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Jours',
                          border: OutlineInputBorder(),
                          suffixText: 'j',
                        ),
                        validator: _validateDuration,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Heures',
                          border: OutlineInputBorder(),
                          suffixText: 'h',
                        ),
                        validator: _validateDuration,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Couleur',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ColorPickerField(
                  selected: _selectedColor,
                  onChanged: (BoxColorType color) {
                    setState(() => _selectedColor = color);
                  },
                ),
                const SizedBox(height: 24),
                GroupSelectorField(
                  groups: groups,
                  selectedGroupId: _selectedGroupId,
                  onChanged: (String? groupId) {
                    setState(() => _selectedGroupId = groupId);
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Enregistrer' : 'Créer la lipo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
