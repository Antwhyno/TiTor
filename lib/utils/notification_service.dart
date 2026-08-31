import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/box_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialise le moteur de notifications et les fuseaux horaires
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Demande la permission système à l'utilisateur
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Génère un entier 32-bit stable à partir de l'UUID de la boîte
  static int _generateNotificationId(String boxId) {
    return boxId.hashCode & 0x7FFFFFFF;
  }

  /// Programme une notification système à la date d'expiration de la boîte
  static Future<void> scheduleBoxExpiration(BoxModel box) async {
    // Si la boîte est déjà expirée, on ne planifie rien
    if (box.isExpired()) return;

    final int notificationId = _generateNotificationId(box.id);
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(box.expiresAt, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'box_expiration_channel',
      'Expiration des Boîtes',
      channelDescription:
          'Alertes déclenchées à l\'expiration d\'une boîte TiTor',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Boîte expirée ! 📦',
      'Le délai pour votre boîte "${box.name}" est arrivé à terme.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Annule la notification programmée associée à une boîte
  static Future<void> cancelBoxNotification(String boxId) async {
    final int notificationId = _generateNotificationId(boxId);
    await _notificationsPlugin.cancel(notificationId);
  }
}
