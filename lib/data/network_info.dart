// lib/data/network_info.dart

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Implémentation temporaire (par défaut connecté)
    return true;
  }
}
