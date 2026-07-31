import 'dart:io';

/// Service utilitaire permettant de vérifier la disponibilité d'une
/// connexion réseau, sans dépendance externe (utilise `dart:io`).
///
/// Les fonctionnalités principales de l'application fonctionnent
/// entièrement hors-ligne (stockage local via sqflite). Ce service est
/// prévu pour les futures fonctionnalités de synchronisation distante
/// (voir [BoxRepository.syncWithRemote]) et illustre la gestion du cas
/// limite "absence de réseau".
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on Exception {
      return false;
    }
  }
}
