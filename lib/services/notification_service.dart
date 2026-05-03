import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Pedir permissão explicitamente (Obrigatório no Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // Configuração para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Inicializa o plugin
    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    // Configura os detalhes da notificação (som, importância, etc)
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pricetrail_channel', // ID do canal
      'PriceTrail Notifications', // Nome do canal
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Dispara a notificação
    await _notificationsPlugin.show(
      id: 0, // ID da notificação
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}