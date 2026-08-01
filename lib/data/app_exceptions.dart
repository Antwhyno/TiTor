/// Exceptions personnalisées de l'application.
///
/// Elles permettent de distinguer les erreurs métier des erreurs
/// techniques et d'afficher des messages clairs et localisés à
/// l'utilisateur, sans jamais laisser fuiter d'exceptions bas-niveau
/// (SQLite, sockets, etc.) jusqu'à l'interface.
library app_exceptions;

/// Exception de base pour toutes les erreurs applicatives.
abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Levée en cas d'échec d'accès à la base de données locale.
class DatabaseAccessException extends AppException {
  const DatabaseAccessException([
    super.message = "Impossible d'accéder à la base de données locale.",
  ]);
}

/// Levée lorsque des données attendues sont nulles ou corrompues.
class InvalidDataException extends AppException {
  const InvalidDataException([
    super.message = 'Les données reçues sont invalides ou incomplètes.',
  ]);
}

/// Levée lorsqu'une opération nécessite une connexion réseau absente.
class NoNetworkException extends AppException {
  const NoNetworkException([
    super.message = 'Aucune connexion réseau disponible.',
  ]);
}

/// Levée lorsqu'une entité recherchée (boîte, groupe) est introuvable.
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = "L'élément demandé est introuvable.",
  ]);
}
