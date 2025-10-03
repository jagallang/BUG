import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../datasources/mission_remote_datasource.dart';
import '../repositories/mission_repository_impl.dart';
import '../../domain/repositories/mission_repository.dart';
import '../../domain/usecases/create_mission_usecase.dart';
import '../../domain/usecases/get_missions_usecase.dart';
import '../../domain/usecases/approve_mission_usecase.dart';
import '../../domain/usecases/start_mission_usecase.dart';

// ========================================
// Datasource Provider
// ========================================

final missionRemoteDatasourceProvider = Provider<MissionRemoteDatasource>((ref) {
  return MissionRemoteDatasource(
    firestore: FirebaseFirestore.instance,
  );
});

// ========================================
// Repository Provider
// ========================================

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final datasource = ref.read(missionRemoteDatasourceProvider);
  return MissionRepositoryImpl(datasource);
});

// ========================================
// UseCase Providers
// ========================================

final createMissionUseCaseProvider = Provider<CreateMissionUseCase>((ref) {
  final repository = ref.read(missionRepositoryProvider);
  return CreateMissionUseCase(repository);
});

final getMissionsUseCaseProvider = Provider<GetMissionsUseCase>((ref) {
  final repository = ref.read(missionRepositoryProvider);
  return GetMissionsUseCase(repository);
});

final approveMissionUseCaseProvider = Provider<ApproveMissionUseCase>((ref) {
  final repository = ref.read(missionRepositoryProvider);
  return ApproveMissionUseCase(repository);
});

final rejectMissionUseCaseProvider = Provider<RejectMissionUseCase>((ref) {
  final repository = ref.read(missionRepositoryProvider);
  return RejectMissionUseCase(repository);
});

final startMissionUseCaseProvider = Provider<StartMissionUseCase>((ref) {
  final repository = ref.read(missionRepositoryProvider);
  return StartMissionUseCase(repository);
});
