import 'package:flutter/material.dart';

import '../models/box_model.dart';

/// Avatar circulaire affichant l'icône d'une lipo.
///
/// Utilise la couleur libre choisie par l'utilisateur à la création
/// ([BoxModel.iconColor]) si elle existe. Sinon, affiche un dégradé de
/// blancs par défaut, avec une icône grise pour rester lisible.
class LipoIconAvatar extends StatelessWidget {
  final BoxModel box;
  final double radius;

  const LipoIconAvatar({super.key, required this.box, this.radius = 24});

  static const Gradient _defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Colors.white, Color(0xFFE0E0E0)],
  );

  @override
  Widget build(BuildContext context) {
    final Color? iconColor = box.iconColor;
    final double diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor?.withValues(alpha: 0.2),
        gradient: iconColor == null ? _defaultGradient : null,
        border: iconColor == null
            ? Border.all(color: const Color(0xFFBDBDBD))
            : null,
      ),
      child: Icon(
        box.icon,
        size: radius,
        color: iconColor ?? const Color(0xFF757575),
      ),
    );
  }
}
