import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

/// v2.9.0: Firebase Storage 서비스 (웹/모바일 통합)
/// 미션 스크린샷 업로드 관리 - XFile 기반
class StorageService {
  // v2.128.0: 명시적 버킷 지정으로 "No object exists" 에러 방지
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(bucket: 'gs://bugcash');

  /// v2.115.0: 미션 스크린샷 업로드 (XFile 지원 + 재시도 로직)
  ///
  /// [workflowId]: 미션 워크플로우 ID
  /// [dayNumber]: 일차 (1부터 시작)
  /// [file]: 업로드할 이미지 파일 (XFile)
  /// [maxRetries]: 최대 재시도 횟수 (기본값: 3)
  ///
  /// Returns: Firebase Storage 다운로드 URL
  /// Throws: 파일 크기 초과, 타입 불일치, 업로드 실패 등
  Future<String> uploadMissionScreenshot({
    required String workflowId,
    required int dayNumber,
    required XFile file,
    int maxRetries = 3,
  }) async {
    // 1. 파일 크기 검증 (5MB)
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      throw Exception('파일 크기가 너무 큽니다. 최대 5MB까지 업로드 가능합니다.');
    }

    // 2. 파일 타입 검증 (이미지만 허용)
    final fileName = file.name.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last;

    if (!allowedExtensions.contains(extension)) {
      throw Exception('이미지 파일만 업로드 가능합니다. (jpg, png, gif, webp)');
    }

    AppLogger.info('Uploading screenshot: workflowId=$workflowId, day=$dayNumber, size=${(fileSize / 1024).toStringAsFixed(1)}KB', 'StorageService');

    // 3. Storage 경로 생성
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'mission_screenshots/$workflowId/day_$dayNumber/$timestamp.$extension';

    // v2.115.0: 재시도 로직 (exponential backoff)
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        attempt++;

        if (attempt > 1) {
          // 재시도 전 대기 (exponential backoff: 1s, 2s, 4s)
          final delaySeconds = (1 << (attempt - 2)); // 2^(attempt-2)
          AppLogger.info('Retry attempt $attempt/$maxRetries after ${delaySeconds}s delay...', 'StorageService');
          await Future.delayed(Duration(seconds: delaySeconds));
        }

        // 4. v2.120.0: XFile 업로드 (웹/모바일 통합) + 60초 타임아웃
        final ref = _storage.ref().child(path);
        final bytes = await file.readAsBytes();

        // v2.120.0: UploadTask 생성 및 대기 (타임아웃 수정)
        final uploadTask = ref.putData(bytes);

        // 타임아웃 적용 (60초)
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            uploadTask.cancel();
            throw Exception('업로드 시간 초과 (60초). Firebase Storage 서비스가 응답하지 않습니다.');
          },
        );

        // 5. 다운로드 URL 획득
        final downloadUrl = await snapshot.ref.getDownloadURL();

        AppLogger.info('✅ Screenshot uploaded successfully (attempt $attempt): $downloadUrl', 'StorageService');
        return downloadUrl;

      } on FirebaseException catch (e) {
        lastError = Exception('Firebase Storage error: ${e.code} - ${e.message}');

        // 재시도 가능한 에러인지 확인 (503, 408, 429 등 일시적 에러)
        final isRetriable = e.code == 'unavailable' ||
                            e.code == 'deadline-exceeded' ||
                            e.code == 'resource-exhausted' ||
                            e.message?.contains('503') == true ||
                            e.message?.contains('408') == true ||
                            e.message?.contains('429') == true;

        if (!isRetriable || attempt >= maxRetries) {
          AppLogger.error('Firebase Storage error (not retriable or max retries): ${e.code} - ${e.message}', 'StorageService');
          throw Exception('이미지 업로드 실패: ${e.message}');
        }

        AppLogger.warning('Retriable Firebase Storage error: ${e.code} - ${e.message}', 'StorageService');
      } catch (e) {
        lastError = Exception('Upload error: $e');

        // 일반 에러는 재시도하지 않음
        AppLogger.error('Upload error: $e', 'StorageService');
        rethrow;
      }
    }

    // 모든 재시도 실패
    AppLogger.error('All $maxRetries upload attempts failed', 'StorageService');
    throw lastError ?? Exception('이미지 업로드 실패: 최대 재시도 횟수 초과');
  }

  /// v2.9.0: 여러 스크린샷 일괄 업로드 (XFile 지원)
  ///
  /// Returns: 업로드된 URL 목록
  Future<List<String>> uploadMultipleScreenshots({
    required String workflowId,
    required int dayNumber,
    required List<XFile> files,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < files.length; i++) {
      try {
        final url = await uploadMissionScreenshot(
          workflowId: workflowId,
          dayNumber: dayNumber,
          file: files[i],
        );
        urls.add(url);
        AppLogger.info('Uploaded ${i + 1}/${files.length} screenshots', 'StorageService');
      } catch (e) {
        AppLogger.error('Failed to upload screenshot ${i + 1}: $e', 'StorageService');
        // 실패한 파일은 건너뛰고 계속 진행
      }
    }

    return urls;
  }

  /// v2.114.0: 앱 스크린샷 업로드 (재시도 로직 포함)
  ///
  /// [appId]: 앱 ID
  /// [file]: 업로드할 이미지 파일 (XFile)
  /// [index]: 스크린샷 인덱스 (0, 1, 2)
  /// [maxRetries]: 최대 재시도 횟수 (기본값: 3)
  ///
  /// Returns: Firebase Storage 다운로드 URL
  /// Throws: 파일 크기 초과, 타입 불일치, 업로드 실패 등
  Future<String> uploadAppScreenshot({
    required String appId,
    required XFile file,
    required int index,
    int maxRetries = 3,
  }) async {
    // 1. 파일 크기 검증 (5MB)
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      throw Exception('파일 크기가 너무 큽니다. 최대 5MB까지 업로드 가능합니다.');
    }

    // 2. 파일 타입 검증 (이미지만 허용)
    final fileName = file.name.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last;

    if (!allowedExtensions.contains(extension)) {
      throw Exception('이미지 파일만 업로드 가능합니다. (jpg, png, gif, webp)');
    }

    AppLogger.info('Uploading app screenshot: appId=$appId, index=$index, size=${(fileSize / 1024).toStringAsFixed(1)}KB', 'StorageService');

    // 3. Storage 경로 생성: app_screenshots/{appId}/screenshot_{index}.{ext}
    final path = 'app_screenshots/$appId/screenshot_$index.$extension';

    // v2.114.0: 재시도 로직 (exponential backoff)
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        attempt++;

        if (attempt > 1) {
          // 재시도 전 대기 (exponential backoff: 1s, 2s, 4s)
          final delaySeconds = (1 << (attempt - 2)); // 2^(attempt-2)
          AppLogger.info('Retry attempt $attempt/$maxRetries after ${delaySeconds}s delay...', 'StorageService');
          await Future.delayed(Duration(seconds: delaySeconds));
        }

        // 4. v2.120.0: XFile 업로드 (웹/모바일 통합) + 60초 타임아웃
        final ref = _storage.ref().child(path);
        final bytes = await file.readAsBytes();

        // v2.120.0: UploadTask 생성 및 대기 (타임아웃 수정)
        final uploadTask = ref.putData(bytes);

        // 타임아웃 적용 (60초)
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            uploadTask.cancel();
            throw Exception('업로드 시간 초과 (60초). Firebase Storage 서비스가 응답하지 않습니다.');
          },
        );

        // 5. 다운로드 URL 획득
        final downloadUrl = await snapshot.ref.getDownloadURL();

        AppLogger.info('✅ App screenshot uploaded successfully (attempt $attempt): $downloadUrl', 'StorageService');
        return downloadUrl;

      } on FirebaseException catch (e) {
        lastError = Exception('Firebase Storage error: ${e.code} - ${e.message}');

        // 재시도 가능한 에러인지 확인 (503, 408, 429 등 일시적 에러)
        final isRetriable = e.code == 'unavailable' ||
                            e.code == 'deadline-exceeded' ||
                            e.code == 'resource-exhausted' ||
                            e.message?.contains('503') == true ||
                            e.message?.contains('408') == true ||
                            e.message?.contains('429') == true;

        if (!isRetriable || attempt >= maxRetries) {
          AppLogger.error('Firebase Storage error (not retriable or max retries): ${e.code} - ${e.message}', 'StorageService');
          throw Exception('이미지 업로드 실패: ${e.message}');
        }

        AppLogger.warning('Retriable Firebase Storage error: ${e.code} - ${e.message}', 'StorageService');
      } catch (e) {
        lastError = Exception('Upload error: $e');

        // 일반 에러는 재시도하지 않음
        AppLogger.error('Upload error: $e', 'StorageService');
        rethrow;
      }
    }

    // 모든 재시도 실패
    AppLogger.error('All $maxRetries upload attempts failed', 'StorageService');
    throw lastError ?? Exception('이미지 업로드 실패: 최대 재시도 횟수 초과');
  }

  /// 미션 스크린샷 삭제
  ///
  /// [downloadUrl]: Firebase Storage 다운로드 URL
  Future<void> deleteScreenshot(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      AppLogger.info('Screenshot deleted: $downloadUrl', 'StorageService');
    } on FirebaseException catch (e) {
      AppLogger.error('Failed to delete screenshot: ${e.code} - ${e.message}', 'StorageService');
      // 삭제 실패해도 에러 throw 안 함 (무시)
    }
  }
}
