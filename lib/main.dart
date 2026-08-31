import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/box/box_bloc.dart';
import 'blocs/box/box_event.dart';
import 'blocs/group/group_bloc.dart';
import 'blocs/group/group_event.dart';
import 'screens/home_screen.dart';
import 'utils/notification_service.dart';

void main() async {
  // 1. Garantit l'initialisation du moteur Flutter avant les appels système
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialise le gestionnaire de notifications et les fuseaux horaires
  await NotificationService.init();

  // 3. Lance l'arbre de composants
  runApp(const OrganizerApp());
}

/// Point d'entrée de l'application. Met en place les [BlocProvider]
/// nécessaires au fonctionnement de l'ensemble de l'arborescence de
/// widgets et déclenche le chargement initial des données.
class OrganizerApp extends StatelessWidget {
  const OrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoxBloc>(
      create: (BuildContext context) => BoxBloc()..add(const LoadBoxes()),
      child: BlocProvider<GroupBloc>(
        create: (BuildContext context) => GroupBloc(
          onBoxesChanged: () => context.read<BoxBloc>().add(const LoadBoxes()),
        )..add(const LoadGroups()),
        child: MaterialApp(
          title: 'TiTor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF3F51B5),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
