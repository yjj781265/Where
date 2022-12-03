import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:social_login_buttons/social_login_buttons.dart';
import 'package:where/bloc/login_bloc.dart';
import 'package:where/home.dart';
import 'package:where/service/firestore_service.dart';

import 'firebase_options.dart';
import 'model/member.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((value) {
    runApp(FirebaseAuth.instance.currentUser == null
        ? const Login()
        : const Home());
  }, onError: (e) {
    if (kDebugMode) {
      print(e.toString());
    }
    runApp(const LoginFailedWidget());
  });
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  final p = await Geolocator.getCurrentPosition();
  await _updateMember(p);
  BackgroundFetch.finish(taskId);
}

Future<void> _updateMember(Position p) async {
  if (FirebaseAuth.instance.currentUser == null) {
    return;
  }
  Member member = Member(
    lat: p.latitude,
    lng: p.longitude,
    timestampInMs: p.timestamp?.millisecondsSinceEpoch ?? -1,
    name: FirebaseAuth.instance.currentUser?.displayName ?? '',
    url: FirebaseAuth.instance.currentUser?.photoURL ?? '',
    id: FirebaseAuth.instance.currentUser?.uid ?? '',
  );

  await FireStoreService().updateMember(member);
}

class Login extends StatelessWidget {
  const Login({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
                flex: 4, child: Lottie.asset('assets/location_share.json')),
            Flexible(
              fit: FlexFit.loose,
              flex: 2,
              child: BlocProvider(
                create: (context) => LoginBloc(
                    googleSignIn: GoogleSignIn(),
                    firebaseAuth: FirebaseAuth.instance),
                child: const LoginButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginFailed) {
          print(state.errorMsg);
        }

        if (state is LoginSuccess) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const Home()));
        }
      },
      child: FittedBox(
        child: BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
          if (state is LoginLoading) {
            return const CircularProgressIndicator();
          }

          return SocialLoginButton(
            buttonType: SocialLoginButtonType.google,
            onPressed: () {
              // with extensions
              context.read<LoginBloc>().add(OnGoogleButtonPressed());
            },
          );
        }),
      ),
    );
  }
}

class LoginFailedWidget extends StatelessWidget {
  const LoginFailedWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text("Login Failed");
  }
}
