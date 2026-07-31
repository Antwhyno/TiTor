import 'dart:async';

import 'package:flutter/material.dart';

/// Affiche un compte à rebours vivant jusqu'à [expiresAt], mis à jour
/// chaque seconde. Passe dans un état visuel "expiré" distinct
/// lorsque la date est dépassée, ce qui matérialise l'alarme associée
/// au chronomètre de la boîte.
class CountdownTimerWidget extends StatefulWidget {
  final DateTime expiresAt;

  const CountdownTimerWidget({super.key, required this.expiresAt});

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _ticker;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    setState(() {
      _remaining = widget.expiresAt.difference(DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      setState(() {
        _remaining = widget.expiresAt.difference(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final bool isExpired = duration.isNegative;
    final Duration absolute = duration.abs();
    final int days = absolute.inDays;
    final int hours = absolute.inHours % 24;
    final int minutes = absolute.inMinutes % 60;
    final int seconds = absolute.inSeconds % 60;

    final String value = days > 0
        ? '${days}j ${hours.toString().padLeft(2, '0')}h'
        : '${hours.toString().padLeft(2, '0')}h '
            '${minutes.toString().padLeft(2, '0')}m '
            '${seconds.toString().padLeft(2, '0')}s';

    return isExpired ? 'Expirée depuis $value' : value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _remaining.isNegative;
    final Color color = isExpired
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          isExpired ? Icons.alarm_on : Icons.timer_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_remaining),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
