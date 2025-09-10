import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  // Create a new payment
  Future<Either<Failure, Payment>> createPayment({
    required String userId,
    required double amount,
    required PaymentMethod method,
    String? missionId,
    Map<String, dynamic>? metadata,
  });

  // Process payment with payment gateway
  Future<Either<Failure, Payment>> processPayment({
    required String paymentId,
    required Map<String, dynamic> paymentDetails,
  });

  // Get payment by ID
  Future<Either<Failure, Payment>> getPaymentById(String paymentId);

  // Get user's payment history
  Future<Either<Failure, List<Payment>>> getUserPayments({
    required String userId,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  // Cancel payment
  Future<Either<Failure, Payment>> cancelPayment(String paymentId);

  // Refund payment
  Future<Either<Failure, Payment>> refundPayment({
    required String paymentId,
    double? partialAmount,
    String? reason,
  });

  // Verify payment status with payment gateway
  Future<Either<Failure, Payment>> verifyPaymentStatus(String paymentId);

  // Get payment statistics
  Future<Either<Failure, Map<String, dynamic>>> getPaymentStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // Stream of payment status updates
  Stream<Payment> watchPaymentStatus(String paymentId);
}