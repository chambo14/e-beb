import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/cotisation_remote_datasource.dart';
import '../../data/datasources/epargne_remote_datasource.dart';
import '../../data/datasources/mobile_money_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/datasources/page_remote_datasource.dart';
import '../../data/datasources/plateforme_remote_datasource.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/datasources/utilisateur_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/cotisation_repository_impl.dart';
import '../../data/repositories/epargne_repository_impl.dart';
import '../../data/repositories/mobile_money_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/page_repository_impl.dart';
import '../../data/repositories/plateforme_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/utilisateur_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/cotisation_repository.dart';
import '../../domain/repositories/epargne_repository.dart';
import '../../domain/repositories/mobile_money_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/page_repository.dart';
import '../../domain/repositories/plateforme_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/utilisateur_repository.dart';

/// Injection de dépendances : les écrans ne connaissent que les contrats du
/// domaine, jamais les implémentations Dio.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
  );
});

final utilisateurRepositoryProvider = Provider<UtilisateurRepository>((ref) {
  return UtilisateurRepositoryImpl(
    UtilisateurRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final cotisationRepositoryProvider = Provider<CotisationRepository>((ref) {
  return CotisationRepositoryImpl(
    CotisationRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final mobileMoneyRepositoryProvider = Provider<MobileMoneyRepository>((ref) {
  return MobileMoneyRepositoryImpl(
    MobileMoneyRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final epargneRepositoryProvider = Provider<EpargneRepository>((ref) {
  return EpargneRepositoryImpl(
    EpargneRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    TransactionRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    NotificationRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final plateformeRepositoryProvider = Provider<PlateformeRepository>((ref) {
  return PlateformeRepositoryImpl(
    PlateformeRemoteDataSource(ref.watch(apiClientProvider)),
  );
});

final pageRepositoryProvider = Provider<PageRepository>((ref) {
  return PageRepositoryImpl(
    PageRemoteDataSource(ref.watch(apiClientProvider)),
  );
});
