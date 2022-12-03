part of 'home_bloc.dart';

@immutable
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeFailed extends HomeState {}

class HomeSuccess extends HomeState {
  final List<MemberModel> members;
  final Position currentP;

  HomeSuccess({this.members = const [], required this.currentP});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSuccess &&
          runtimeType == other.runtimeType &&
          members == other.members;

  @override
  int get hashCode => members.hashCode;
}

class HomeSignOut extends HomeState {}
