import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();

// App module for dependency injection
@module
abstract class AppModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  @lazySingleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;
  
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn();
}

// Repository module for dependency injection
@module
abstract class RepositoryModule {
  // Payment Repository
  // @LazySingleton(as: PaymentRepository)
  // PaymentRepositoryImpl get paymentRepository => PaymentRepositoryImpl(
  //   firestore: getIt<FirebaseFirestore>(),
  // );
  
  // Chat Repository  
  // @LazySingleton(as: ChatRepository)
  // ChatRepositoryImpl get chatRepository => ChatRepositoryImpl(
  //   firestore: getIt<FirebaseFirestore>(),
  //   storage: getIt<FirebaseStorage>(),
  // );
}

// Use cases module
@module
abstract class UseCaseModule {
  // Payment Use Cases
  // @injectable
  // ProcessPayment get processPayment => ProcessPayment(
  //   repository: getIt<PaymentRepository>(),
  // );
  
  // Chat Use Cases
  // @injectable
  // SendMessage get sendMessage => SendMessage(
  //   repository: getIt<ChatRepository>(),
  // );
}