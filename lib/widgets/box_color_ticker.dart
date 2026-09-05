import 'dart:async';

import 'package:flutter/material.dart';

import '../models/box_model.dart';

/// Recalcule et fournit périodiquement la couleur d'affichage d'une
/// lipo ([BoxModel.displayColor]), afin que l'indicateur de couleur
/// automatique (dégradé vert -> rouge selon la proximité de
/// l'expiration) évolue visuellement dans le temps, sans qu'une
/// action de l'utilisateur soit nécessaire.
///
/// Si une couleur manuelle est définie sur la lipo, la couleur fournie
/// reste simplement figée sur cette couleur manuelle.
class BoxColorTicker extends StatefulWidget {
  final BoxModel box;
  final Widget Function(BuildContext context, Color color) builder;

  /// Fréquence de rafraîchissement. Une minute suffit largement ici :
  /// le dégradé de couleur automatique évolue sur des durées de
  /// plusieurs heures à plusieurs jours, une précision à la seconde
  /// n'apporterait donc rien à l'utilisateur.
  final Duration refreshInterval;

  const BoxColorTicker({
    super.key,
    required this.box,
    required this.builder,
    this.refreshInterval = const Duration(minutes: 1),
  });

  @override
  State<BoxColorTicker> createState() => _BoxColorTickerState();
}

class _BoxColorTickerState extends State<BoxColorTicker> {
  late Timer _ticker;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = widget.box.displayColor();
    _ticker = Timer.periodic(widget.refreshInterval, _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    setState(() => _color = widget.box.displayColor());
  }

  @override
  void didUpdateWidget(covariant BoxColorTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool relevantFieldsChanged =
        oldWidget.box.manualColorValue != widget.box.manualColorValue ||
            oldWidget.box.expiresAt != widget.box.expiresAt ||
            oldWidget.box.createdAt != widget.box.createdAt;
    if (relevantFieldsChanged) {
      setState(() => _color = widget.box.displayColor());
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _color);
}
