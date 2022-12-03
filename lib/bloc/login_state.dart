part of 'login_bloc.dart';

@immutable
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailed extends LoginState {
  final String _errorMsg;

  LoginFailed(this._errorMsg);

  String get errorMsg => _errorMsg;
}
