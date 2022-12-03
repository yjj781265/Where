part of 'home_bloc.dart';

@immutable
abstract class HomeEvent {}

class InitLocation extends HomeEvent {}

class MembersLoaded extends HomeEvent {
  final List<MemberModel> members;
  final Position currentP;

  MembersLoaded(this.members, this.currentP);
}

class SignOutEvent extends HomeEvent {}
