import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  LoginBloc({required this.googleSignIn, required this.firebaseAuth})
      : super(LoginInitial()) {
    on<LoginEvent>((event, emit) async {
      if (event is OnGoogleButtonPressed) {
        await _handleGoogleButtonPressed(emit);
      }
    });
  }

  Future<void> _handleGoogleButtonPressed(Emitter emit) async {
    try {
      emit(LoginLoading());
      final userCredential = await _signInWithGoogle();
      if (userCredential.user == null) {
        emit(LoginFailed("user is null"));
      } else {
        emit(LoginSuccess());
      }
    } catch (error) {
      emit(LoginFailed(error.toString()));
    }
  }

  Future<UserCredential> _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await firebaseAuth.signInWithCredential(credential);
  }
}
