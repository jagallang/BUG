part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuth extends AuthEvent {
  const CheckAuth();
}

class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

class SignOut extends AuthEvent {
  const SignOut();
}