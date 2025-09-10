import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class ProcessPayment extends UseCase<Payment, ProcessPaymentParams> {
  final PaymentRepository repository;

  ProcessPayment(this.repository);

  @override
  Future<Either<Failure, Payment>> call(ProcessPaymentParams params) async {
    // Step 1: Create payment record
    final createResult = await repository.createPayment(
      userId: params.userId,
      amount: params.amount,
      method: params.method,
      missionId: params.missionId,
      metadata: params.metadata,
    );

    return createResult.fold(
      (failure) => Left(failure),
      (payment) async {
        // Step 2: Process payment with gateway
        final processResult = await repository.processPayment(
          paymentId: payment.id,
          paymentDetails: params.paymentDetails,
        );

        return processResult;
      },
    );
  }
}

class ProcessPaymentParams extends Equatable {
  final String userId;
  final double amount;
  final PaymentMethod method;
  final Map<String, dynamic> paymentDetails;
  final String? missionId;
  final Map<String, dynamic>? metadata;

  const ProcessPaymentParams({
    required this.userId,
    required this.amount,
    required this.method,
    required this.paymentDetails,
    this.missionId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        userId,
        amount,
        method,
        paymentDetails,
        missionId,
        metadata,
      ];
}