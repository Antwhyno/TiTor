import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/box/box_bloc.dart';
import '../blocs/box/box_event.dart';
import '../blocs/box/box_state.dart';
import '../blocs/group/group_bloc.dart';
import '../blocs/group/group_event.dart';
import '../blocs/group/group_state.dart';
import '../models/box_group_model.dart';
import '../models/box_model.dart';
import '../widgets/add_edit_group_dialog.dart';
import '../widgets/box_card.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/group_card.dart';
import 'add_edit_box_screen.dart';
import 'box_detail_screen.dart';
import 'group_detail_screen.dart';

/// Écran principal de l'application, organisé en deux onglets : la
/// liste des lipos sans groupe et la liste des groupes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddBoxScreen(BuildContext context) {
    final BoxBloc boxBloc = context.read<BoxBloc>();
    final GroupBloc groupBloc = context.read<GroupBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<BoxBloc>.value(
          value: boxBloc,
          child: BlocProvider<GroupBloc>.value(
            value: groupBloc,
            child: const AddEditBoxScreen(),
          ),
        ),
      ),
    );
  }

  void _openBoxDetail(BuildContext context, BoxModel box) {
    final BoxBloc boxBloc = context.read<BoxBloc>();
    final GroupBloc groupBloc = context.read<GroupBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<BoxBloc>.value(
          value: boxBloc,
          child: BlocProvider<GroupBloc>.value(
            value: groupBloc,
            child: BoxDetailScreen(boxId: box.id),
          ),
        ),
      ),
    );
  }

  void _openGroupDetail(BuildContext context, BoxGroupModel group) {
    final BoxBloc boxBloc = context.read<BoxBloc>();
    final GroupBloc groupBloc = context.read<GroupBloc>();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => BlocProvider<BoxBloc>.value(
          value: boxBloc,
          child: BlocProvider<GroupBloc>.value(
            value: groupBloc,
            child: GroupDetailScreen(groupId: group.id),
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const AddEditGroupDialog(),
    );
    if (name != null && context.mounted) {
      context.read<GroupBloc>().add(AddGroupRequested(name));
    }
  }

  Future<void> _editGroup(BuildContext context, BoxGroupModel group) async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          AddEditGroupDialog(initialName: group.name),
    );
    if (name != null && context.mounted) {
      context
          .read<GroupBloc>()
          .add(UpdateGroupRequested(groupId: group.id, name: name));
    }
  }

  Future<void> _deleteGroup(BuildContext context, BoxGroupModel group) async {
    final bool confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Supprimer le groupe',
      message: 'Le groupe "${group.name}" sera supprimé. Ses lipos seront '
          'conservées et deviendront des lipos sans groupe.',
    );
    if (confirmed && context.mounted) {
      context.read<GroupBloc>().add(DeleteGroupRequested(group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Lipos', icon: Icon(Icons.inbox_outlined)),
            Tab(text: 'Groupes', icon: Icon(Icons.folder_copy_outlined)),
          ],
        ),
      ),
      body: BlocListener<BoxBloc, BoxState>(
        listenWhen: (BoxState previous, BoxState current) =>
            current is BoxError,
        listener: (BuildContext context, BoxState state) {
          if (state is BoxError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocListener<GroupBloc, GroupState>(
          listenWhen: (GroupState previous, GroupState current) =>
              current is GroupError,
          listener: (BuildContext context, GroupState state) {
            if (state is GroupError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _BoxesTab(
                onBoxTap: (BoxModel box) => _openBoxDetail(context, box),
              ),
              _GroupsTab(
                onCreateGroup: () => _createGroup(context),
                onGroupTap: (BoxGroupModel group) =>
                    _openGroupDetail(context, group),
                onEditGroup: (BoxGroupModel group) =>
                    _editGroup(context, group),
                onDeleteGroup: (BoxGroupModel group) =>
                    _deleteGroup(context, group),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (BuildContext context, Widget? child) {
          final bool isBoxesTab = _tabController.index == 0;
          return FloatingActionButton.extended(
            onPressed: () =>
                isBoxesTab ? _openAddBoxScreen(context) : _createGroup(context),
            icon: const Icon(Icons.add),
            label: Text(isBoxesTab ? 'Nouvelle lipo' : 'Nouveau groupe'),
          );
        },
      ),
    );
  }
}

/// Onglet listant les lipos sans groupe.
class _BoxesTab extends StatelessWidget {
  final ValueChanged<BoxModel> onBoxTap;

  const _BoxesTab({required this.onBoxTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoxBloc, BoxState>(
      builder: (BuildContext context, BoxState state) {
        if (state is BoxLoading || state is BoxInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<BoxModel> boxes = state is BoxLoaded
            ? state.ungroupedBoxes
            : state is BoxError
                ? state.previousBoxes
                    .where((BoxModel box) => box.groupId == null)
                    .toList()
                : const <BoxModel>[];

        if (boxes.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            message: "Aucune lipo pour l'instant.\n"
                "Touchez le bouton '+' pour en créer une.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<BoxBloc>().add(const LoadBoxes()),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: boxes.length,
            itemBuilder: (BuildContext context, int index) {
              final BoxModel box = boxes[index];
              return BoxCard(box: box, onTap: () => onBoxTap(box));
            },
          ),
        );
      },
    );
  }
}

/// Onglet listant les groupes de lipos.
class _GroupsTab extends StatelessWidget {
  final VoidCallback onCreateGroup;
  final ValueChanged<BoxGroupModel> onGroupTap;
  final ValueChanged<BoxGroupModel> onEditGroup;
  final ValueChanged<BoxGroupModel> onDeleteGroup;

  const _GroupsTab({
    required this.onCreateGroup,
    required this.onGroupTap,
    required this.onEditGroup,
    required this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (BuildContext context, GroupState groupState) {
        if (groupState is GroupLoading || groupState is GroupInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<BoxGroupModel> groups = groupState is GroupLoaded
            ? groupState.groups
            : groupState is GroupError
                ? groupState.previousGroups
                : const <BoxGroupModel>[];

        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.folder_copy_outlined,
            message: 'Aucun groupe pour le moment.',
            actionLabel: 'Créer un groupe',
            onAction: onCreateGroup,
          );
        }

        return BlocBuilder<BoxBloc, BoxState>(
          builder: (BuildContext context, BoxState boxState) {
            final List<BoxModel> boxes = boxState is BoxLoaded
                ? boxState.boxes
                : boxState is BoxError
                    ? boxState.previousBoxes
                    : const <BoxModel>[];

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 88, top: 8),
              itemCount: groups.length,
              itemBuilder: (BuildContext context, int index) {
                final BoxGroupModel group = groups[index];
                final int boxCount = boxes
                    .where((BoxModel box) => box.groupId == group.id)
                    .length;
                return GroupCard(
                  group: group,
                  boxCount: boxCount,
                  onTap: () => onGroupTap(group),
                  onEdit: () => onEditGroup(group),
                  onDelete: () => onDeleteGroup(group),
                );
              },
            );
          },
        );
      },
    );
  }
}
