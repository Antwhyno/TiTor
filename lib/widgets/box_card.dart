import 'package:flutter/material.dart';

import '../models/box_model.dart';
import 'box_color_ticker.dart';
import 'countdown_timer_widget.dart';
import 'lipo_icon_avatar.dart';

/// Carte représentant une lipo dans les listes de l'application.
class BoxCard extends StatelessWidget {
  final BoxModel box;
  final VoidCallback onTap;

  const BoxCard({super.key, required this.box, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  LipoIconAvatar(box: box, radius: 24),
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
