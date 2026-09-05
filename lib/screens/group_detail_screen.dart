import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/box/box_bloc.dart';
import '../blocs/box/box_state.dart';
import '../blocs/group/group_bloc.dart';
import '../blocs/group/group_state.dart';
import '../models/box_group_model.dart';
import '../models/box_model.dart';
import '../widgets/box_card.dart';
import '../widgets/empty_state.dart';
import 'box_detail_screen.dart';

/// Écran de détail d'un groupe : liste les lipos qu'il contient.
class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  BoxGroupModel? _findGroup(GroupState state, String id) {
    if (state is GroupLoaded) {
      final Iterable<BoxGroupModel> matches =
          state.groups.where((BoxGroupModel group) => group.id == id);
      return matches.isEmpty ? null : matches.first;
    }
    if (state is GroupError) {
      final Iterable<BoxGroupModel> matches =
          state.previousGroups.where((BoxGroupModel group) => group.id == id);
      return matches.isEmpty ? null : matches.first;
    }
    return null;
  }

  List<BoxModel> _boxesForGroup(BoxState state, String id) {
    if (state is BoxLoaded) {
      return state.boxesInGroup(id);
    }
    if (state is BoxError) {
      return state.previousBoxes
          .where((BoxModel box) => box.groupId == id)
          .toList();
    }
    return const <BoxModel>[];
  }

  void _openBoxDetail(BuildContext context, BoxModel box) {
    final BoxBloc boxBloc = context.read<BoxBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<BoxBloc>.value(
          value: boxBloc,
          child: BoxDetailScreen(boxId: box.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (BuildContext context, GroupState groupState) {
        final BoxGroupModel? group = _findGroup(groupState, groupId);

        return Scaffold(
          appBar: AppBar(title: Text(group?.name ?? 'Groupe introuvable')),
          body: group == null
              ? const Center(
                  child: Text('Ce groupe a peut-être été supprimé.'),
                )
              : BlocBuilder<BoxBloc, BoxState>(
                  builder: (BuildContext context, BoxState boxState) {
                    final List<BoxModel> boxes =
                        _boxesForGroup(boxState, group.id);

                    if (boxes.isEmpty) {
                      return const EmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'Ce groupe ne contient aucune lipo.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: boxes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final BoxModel box = boxes[index];
                        return BoxCard(
                          box: box,
                          onTap: () => _openBoxDetail(context, box),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
