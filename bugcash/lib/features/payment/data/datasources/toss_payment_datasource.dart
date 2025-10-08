import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/payment_entity.dart';

/// 토스 페이먼츠 API DataSource
class TossPaymentDataSource {
  final String _clientKey; // 클라이언트 키 (프론트엔드용)
  final String _secretKey; // 시크릿 키 (백엔드용)
  final bool _isTestMode; // 테스트 모드 여부

  static const String _baseUrl = 'https://api.tosspayments.com/v1';

  TossPaymentDataSource({
    required String clientKey,
    required String secretKey,
    bool isTestMode = true,
  })  : _clientKey = clientKey,
        _secretKey = secretKey,
        _isTestMode = isTestMode;

  /// 클라이언트 키 반환 (위젯 초기화용)
  String get clientKey => _clientKey;

  /// 결제 승인 요청 (서버 to 서버 통신)
  ///
  /// ⚠️ 보안: 이 메서드는 Cloud Functions에서 호출되어야 합니다!
  /// 클라이언트에서 직접 호출하면 시크릿 키가 노출됩니다.
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/confirm');

    // Basic Authentication (Base64 인코딩)
    final credentials = base64Encode(utf8.encode('$_secretKey:'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw TossPaymentException(
        code: error['code'] ?? 'UNKNOWN_ERROR',
        message: error['message'] ?? '결제 승인 실패',
      );
    }
  }

  /// 결제 취소
  Future<Map<String, dynamic>> cancelPayment({
    required String paymentKey,
    String? cancelReason,
  }) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentKey/cancel');

    final credentials = base64Encode(utf8.encode('$_secretKey:'));

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cancelReason': cancelReason ?? '고객 요청',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw TossPaymentException(
        code: error['code'] ?? 'UNKNOWN_ERROR',
        message: error['message'] ?? '결제 취소 실패',
      );
    }
  }

  /// 결제 조회
  Future<Map<String, dynamic>> getPayment(String paymentKey) async {
    final url = Uri.parse('$_baseUrl/payments/$paymentKey');

    final credentials = base64Encode(utf8.encode('$_secretKey:'));

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Basic $credentials',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw TossPaymentException(
        code: 'NOT_FOUND',
        message: '결제 정보를 찾을 수 없습니다',
      );
    }
  }
}

/// 토스 결제 예외
class TossPaymentException implements Exception {
  final String code;
  final String message;

  TossPaymentException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'TossPaymentException($code): $message';
}
