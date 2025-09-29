import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/provider_app_entity.dart';
import '../../domain/usecases/get_provider_apps_usecase.dart';
import '../../domain/usecases/create_app_usecase.dart';
import '../../domain/usecases/delete_app_usecase.dart';
import '../../data/datasources/app_management_remote_datasource.dart';
import '../../data/repositories/app_management_repository_impl.dart';

// Provider for dependencies
final appManagementDataSourceProvider = Provider<AppManagementRemoteDataSource>((ref) {
  return AppManagementRemoteDataSourceImpl();
});

final appManagementRepositoryProvider = Provider((ref) {
  final dataSource = ref.read(appManagementDataSourceProvider);
  return AppManagementRepositoryImpl(dataSource);
});

final getProviderAppsUseCaseProvider = Provider((ref) {
  final repository = ref.read(appManagementRepositoryProvider);
  return GetProviderAppsUseCase(repository);
});

final createAppUseCaseProvider = Provider((ref) {
  final repository = ref.read(appManagementRepositoryProvider);
  return CreateAppUseCase(repository);
});

final deleteAppUseCaseProvider = Provider((ref) {
  final repository = ref.read(appManagementRepositoryProvider);
  return DeleteAppUseCase(repository);
});

// Provider for getting apps stream
final providerAppsStreamProvider = StreamProvider.family<List<ProviderAppEntity>, String>((ref, providerId) {
  final useCase = ref.read(getProviderAppsUseCaseProvider);
  return useCase(providerId);
});

// State management for app management operations
class AppManagementState {
  final bool isLoading;
  final String? error;
  final bool isCreating;
  final bool isDeleting;

  const AppManagementState({
    this.isLoading = false,
    this.error,
    this.isCreating = false,
    this.isDeleting = false,
  });

  AppManagementState copyWith({
    bool? isLoading,
    String? error,
    bool? isCreating,
    bool? isDeleting,
  }) {
    return AppManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCreating: isCreating ?? this.isCreating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class AppManagementNotifier extends StateNotifier<AppManagementState> {
  final CreateAppUseCase _createAppUseCase;
  final DeleteAppUseCase _deleteAppUseCase;
  final AppManagementRepositoryImpl _repository;

  AppManagementNotifier(
    this._createAppUseCase,
    this._deleteAppUseCase,
    this._repository,
  ) : super(const AppManagementState());

  Future<String?> createApp(ProviderAppEntity app) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final appId = await _createAppUseCase(app);
      state = state.copyWith(isCreating: false);
      return appId;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteApp(String appId) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _deleteAppUseCase(appId);
      state = state.copyWith(isDeleting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyCredentials(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final isValid = await _repository.verifyProviderCredentials(email, password);
      state = state.copyWith(isLoading: false);
      return isValid;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final appManagementProvider = StateNotifierProvider<AppManagementNotifier, AppManagementState>((ref) {
  final createAppUseCase = ref.read(createAppUseCaseProvider);
  final deleteAppUseCase = ref.read(deleteAppUseCaseProvider);
  final repository = ref.read(appManagementRepositoryProvider);

  return AppManagementNotifier(createAppUseCase, deleteAppUseCase, repository);
});