import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

/// v2.9.0: Firebase Storage 서비스 (웹/모바일 통합)
/// 미션 스크린샷 업로드 관리 - XFile 기반
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// v2.9.0: 미션 스크린샷 업로드 (XFile 지원)
  ///
  /// [workflowId]: 미션 워크플로우 ID
  /// [dayNumber]: 일차 (1부터 시작)
  /// [file]: 업로드할 이미지 파일 (XFile)
  ///
  /// Returns: Firebase Storage 다운로드 URL
  /// Throws: 파일 크기 초과, 타입 불일치, 업로드 실패 등
  Future<String> uploadMissionScreenshot({
    required String workflowId,
    required int dayNumber,
    required XFile file,
  }) async {
    try {
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

      // 4. v2.9.0: XFile 업로드 (웹/모바일 통합)
      final ref = _storage.ref().child(path);
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(bytes);

      // 5. 다운로드 URL 획득
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      AppLogger.info('✅ Screenshot uploaded successfully: $downloadUrl', 'StorageService');
      return downloadUrl;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error: ${e.code} - ${e.message}', 'StorageService');
      throw Exception('이미지 업로드 실패: ${e.message}');
    } catch (e) {
      AppLogger.error('Upload error: $e', 'StorageService');
      rethrow;
    }
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
