import 'package:flutter/material.dart';

import '../models/box_model.dart';
import 'box_color_ticker.dart';
import 'countdown_timer_widget.dart';

/// Carte représentant une lipo dans les listes de l'application.
class BoxCard extends StatelessWidget {
  final BoxModel box;
  final VoidCallback onTap;

  const BoxCard({super.key, required this.box, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Couleur choisie à la création de la lipo (catégorie rouge/jaune/vert
    // liée à la durée du chronomètre) : reste fixe sur l'icône, quel que
    // soit le temps qui passe.
    final Color iconColor = box.color.materialColor;

    return BoxColorTicker(
      box: box,
      builder: (BuildContext context, Color proximityColor) {
        // Couleur de fond de toute la carte : reflète le temps restant
        // avant expiration (plus c'est proche, plus c'est rouge ; plus
        // c'est loin, plus c'est vert), ou la couleur manuelle si
        // l'utilisateur en a choisi une.
        final Color cardBackground = proximityColor.withValues(alpha: 0.18);

        return Card(
          color: cardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withValues(alpha: 0.2),
                    child: Icon(box.icon, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          box.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CountdownTimerWidget(expiresAt: box.expiresAt),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: proximityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
