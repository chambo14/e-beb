import '../entities/infos_plateforme.dart';

/// Contrat des informations publiques (aucune authentification requise).
abstract class PlateformeRepository {
  Future<InfosPlateforme> infos();
}
