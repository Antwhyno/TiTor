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
import '../widgets/group_selector_field.dart';
import '../widgets/icon_color_picker_field.dart';

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
  Color? _selectedIconColor;
  String? _selectedGroupId;

  bool get _isEditing => widget.existingBox != null;

  @override
  void initState() {
    super.initState();
    final BoxModel? box = widget.existingBox;
    _nameController = TextEditingController(text: box?.name ?? '');
    _selectedIcon = box?.icon ?? Icons.inbox;
    _selectedColor = box?.color ?? BoxColorType.standard;
    _selectedIconColor = box?.iconColor;
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
      // Valeur par défaut pour une nouvelle lipo : 15 jours (durée
      // unique par défaut, ajustable manuellement ci-dessous).
      _daysController = TextEditingController(text: '15');
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
          iconColor: _selectedIconColor,
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
          iconColor: _selectedIconColor,
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
                  'Couleur de l\'icône',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choisissez n\'importe quelle couleur pour l\'icône. Si '
                  'vous n\'en choisissez pas, elle sera affichée avec un '
                  'dégradé de blancs par défaut.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Center(
                  child: _IconPreview(
                    icon: _selectedIcon,
                    color: _selectedIconColor,
                  ),
                ),
                const SizedBox(height: 12),
                IconColorPickerField(
                  selected: _selectedIconColor,
                  onChanged: (Color? color) {
                    setState(() => _selectedIconColor = color);
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

/// Aperçu de l'icône avec sa couleur (ou le dégradé blanc par défaut),
/// utilisé pendant la création/modification, avant qu'une [BoxModel]
/// complète n'existe.
class _IconPreview extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const _IconPreview({required this.icon, required this.color});

  static const Gradient _defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Colors.white, Color(0xFFE0E0E0)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color?.withValues(alpha: 0.2),
        gradient: color == null ? _defaultGradient : null,
        border: color == null
            ? Border.all(color: const Color(0xFFBDBDBD))
            : null,
      ),
      child: Icon(
        icon,
        size: 32,
        color: color ?? const Color(0xFF757575),
      ),
    );
  }
}
