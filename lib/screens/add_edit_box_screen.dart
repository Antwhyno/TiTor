import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/box/box_bloc.dart';
import '../blocs/box/box_event.dart';
import '../blocs/group/group_bloc.dart';
import '../blocs/group/group_state.dart';
import '../models/box_color_type.dart';
import '../models/box_group_model.dart';
import '../models/box_model.dart';
import '../utils/icon_catalog.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/group_selector_field.dart';
import '../widgets/icon_picker_field.dart';

/// Écran de création ou de modification d'une boîte.
/// Si [existingBox] est fourni, l'écran fonctionne en mode édition.
class AddEditBoxScreen extends StatefulWidget {
  final BoxModel? existingBox;

  const AddEditBoxScreen({super.key, this.existingBox});

  @override
  State<AddEditBoxScreen> createState() => _AddEditBoxScreenState();
}

class _AddEditBoxScreenState extends State<AddEditBoxScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late BoxColorType _selectedColor;
  String? _selectedGroupId;

  bool get _isEditing => widget.existingBox != null;

  @override
  void initState() {
    super.initState();
    final BoxModel? box = widget.existingBox;
    _nameController = TextEditingController(text: box?.name ?? '');
    _selectedIcon = box?.icon ?? IconCatalog.fallback;
    _selectedColor = box?.color ?? BoxColorType.yellow;
    _selectedGroupId = box?.groupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final BoxModel? existingBox = widget.existingBox;
    final BoxBloc boxBloc = context.read<BoxBloc>();

    if (existingBox == null) {
      boxBloc.add(
        AddBoxRequested(
          name: _nameController.text,
          icon: _selectedIcon,
          color: _selectedColor,
          groupId: _selectedGroupId,
        ),
      );
    } else {
      boxBloc.add(
        UpdateBoxRequested(
          boxId: existingBox.id,
          name: _nameController.text,
          icon: _selectedIcon,
          groupId: _selectedGroupId,
          clearGroup: _selectedGroupId == null,
        ),
      );
      if (existingBox.color != _selectedColor) {
        boxBloc.add(
          ChangeBoxColorRequested(
            boxId: existingBox.id,
            newColor: _selectedColor,
          ),
        );
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la boîte' : 'Nouvelle boîte'),
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
                    labelText: 'Nom de la boîte',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 24),
                Text('Icône', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                IconPickerField(
                  selected: _selectedIcon,
                  onChanged: (IconData icon) {
                    setState(() => _selectedIcon = icon);
                  },
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
                  child: Text(_isEditing ? 'Enregistrer' : 'Créer la boîte'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
