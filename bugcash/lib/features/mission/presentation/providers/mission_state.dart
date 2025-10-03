import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/mission_workflow_entity.dart';

part 'mission_state.freezed.dart';

/// Mission State (Presentation Layer)
/// freezed를 사용한 불변 상태 관리
@freezed
class MissionState with _$MissionState {
  const factory MissionState.initial() = _Initial;

  const factory MissionState.loading() = _Loading;

  const factory MissionState.loaded({
    required List<MissionWorkflowEntity> missions,
    @Default(false) bool isRefreshing,
  }) = _Loaded;

  const factory MissionState.error({
    required String message,
    Object? exception,
  }) = _Error;
}

/// Mission Detail State (단일 미션 상세)
@freezed
class MissionDetailState with _$MissionDetailState {
  const factory MissionDetailState.initial() = _DetailInitial;

  const factory MissionDetailState.loading() = _DetailLoading;

  const factory MissionDetailState.loaded({
    required MissionWorkflowEntity mission,
  }) = _DetailLoaded;

  const factory MissionDetailState.error({
    required String message,
  }) = _DetailError;
}
