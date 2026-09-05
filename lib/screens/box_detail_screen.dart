import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/box/box_bloc.dart';
import '../blocs/box/box_event.dart';
import '../blocs/box/box_state.dart';
import '../blocs/group/group_bloc.dart';
import '../models/box_color_type.dart';
import '../models/box_model.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/countdown_timer_widget.dart';
import 'add_edit_box_screen.dart';

/// Écran de détail d'une lipo : affiche ses informations, permet de
/// changer sa couleur, de la modifier ou de la supprimer.
class BoxDetailScreen extends StatelessWidget {
  final String boxId;

  const BoxDetailScreen({super.key, required this.boxId});

  BoxModel? _findBox(BoxState state, String id) {
    if (state is BoxLoaded) {
      final Iterable<BoxModel> matches =
          state.boxes.where((BoxModel box) => box.id == id);
      return matches.isEmpty ? null : matches.first;
    }
    if (state is BoxError) {
      final Iterable<BoxModel> matches =
          state.previousBoxes.where((BoxModel box) => box.id == id);
      return matches.isEmpty ? null : matches.first;
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, BoxModel box) async {
    final bool confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Supprimer la lipo',
      message: 'La lipo "${box.name}" sera définitivement supprimée.',
    );
    if (confirmed && context.mounted) {
      context.read<BoxBloc>().add(DeleteBoxRequested(box.id));
      Navigator.of(context).pop();
    }
  }

  void _openEditScreen(BuildContext context, BoxModel box) {
    final BoxBloc boxBloc = context.read<BoxBloc>();
    final GroupBloc groupBloc = context.read<GroupBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<BoxBloc>.value(
          value: boxBloc,
          child: BlocProvider<GroupBloc>.value(
            value: groupBloc,
            child: AddEditBoxScreen(existingBox: box),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return BlocBuilder<BoxBloc, BoxState>(
      builder: (BuildContext context, BoxState state) {
        final BoxModel? box = _findBox(state, boxId);

        if (box == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lipo introuvable')),
            body: const Center(
              child: Text('Cette lipo a peut-être été supprimée.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(box.name),
            actions: <Widget>[
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEditScreen(context, box),
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, box),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      box.color.materialColor.withValues(alpha: 0.15),
                  child: Icon(
                    box.icon,
                    size: 40,
                    color: box.color.materialColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: CountdownTimerWidget(expiresAt: box.expiresAt)),
              const SizedBox(height: 24),
              _InfoRow(
                label: 'Créée le',
                value: dateFormat.format(box.createdAt),
              ),
              _InfoRow(
                label: 'Expire le',
                value: dateFormat.format(box.expiresAt),
              ),
              const SizedBox(height: 24),
              Text('Couleur', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ColorPickerField(
                selected: box.color,
                onChanged: (BoxColorType newColor) {
                  if (newColor != box.color) {
                    context.read<BoxBloc>().add(
                          ChangeBoxColorRequested(
                            boxId: box.id,
                            newColor: newColor,
                          ),
                        );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
