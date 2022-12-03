import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:where/bloc/home_bloc.dart';
import 'package:where/service/firestore_service.dart';

import 'main.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BlocProvider(
          create: (context) =>
              HomeBloc(FireStoreService(), FirebaseAuth.instance),
          child: Scaffold(
            appBar: AppBar(),
            drawer: SafeArea(
              child: SizedBox(
                width: 150,
                child: Drawer(
                    child: Column(
                  children: const [
                    SignOutButton(),
                  ],
                ) // Populate the Drawer in the next step.
                    ),
              ),
            ),
            body: const Center(child: Map()),
          ),
        ));
  }
}

class Map extends StatelessWidget {
  const Map({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(builder: (context, state) {
      if (state is HomeInitial) {
        context.read<HomeBloc>().add(InitLocation());
        return const CircularProgressIndicator();
      }

      if (state is HomeFailed) {
        context.read<HomeBloc>().add(InitLocation());
        return TextButton(
            onPressed: () {
              context.read<HomeBloc>().add(InitLocation());
            },
            child: const Text('Try Again'));
      }

      if (state is HomeSuccess) {
        return GoogleMap(
          mapType: MapType.normal,
          buildingsEnabled: false,
          myLocationEnabled: true,
          markers: state.members
              .map((e) => Marker(
                  infoWindow: InfoWindow(
                      title: e.member.name,
                      snippet: readableDateTime(
                          DateTime.fromMillisecondsSinceEpoch(
                              e.member.timestampInMs),
                          showTime: true)),
                  markerId: MarkerId(e.member.id),
                  icon: e.bitmapDescriptor,
                  position: LatLng(e.member.lat, e.member.lng)))
              .toSet(),
          initialCameraPosition: CameraPosition(
              zoom: 8,
              target:
                  LatLng(state.currentP.latitude, state.currentP.longitude)),
        );
      }

      return const SizedBox();
    }, listener: (context, state) {
      if (state is HomeFailed) {
        const snackBar = SnackBar(
          content: Text('Failed to find current location'),
          duration: Duration(seconds: 2),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  String readableDateTime(DateTime _dateTime, {bool showTime = false}) {
    if (showTime) {
      return '${DateFormat('hh:mm aa').format(_dateTime.toLocal())} '
          '${getSuffixDateTimeString(_dateTime.toLocal())}';
    }
    final f = DateFormat('MM/dd/yyyy');
    return f.format(_dateTime.toLocal());
  }

  /// Returns the difference (in full days) between the provided date and today.
  int _calculateDifference(DateTime date) {
    final DateTime now = DateTime.now().toLocal();
    return date.difference(now).inDays;
  }

  String getSuffixDateTimeString(DateTime _dateTime) {
    if (_calculateDifference(_dateTime.toLocal()) == 0) {
      return '';
    }

    if (_calculateDifference(_dateTime.toLocal()) == 1) {
      return 'tomorrow';
    }

    if (_calculateDifference(_dateTime.toLocal()) == -1) {
      return 'yesterday';
    }

    final Duration diffDt =
        DateTime.now().toLocal().difference(_dateTime.toLocal());
    if (diffDt.inDays < 365) {
      final DateFormat formatter = DateFormat('MM/dd');
      final String formatted = formatter.format(_dateTime.toLocal());
      return formatted;
    } else {
      final DateFormat formatter = DateFormat('MM/dd/yyyy');
      final String formatted = formatter.format(_dateTime.toLocal());
      return formatted;
    }
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(builder: (context, state) {
      return TextButton.icon(
          onPressed: () {
            context.read<HomeBloc>().add(SignOutEvent());
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'));
    }, listener: (context, state) {
      if (state is HomeSignOut) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const Login()));
      }
    });
  }
}
