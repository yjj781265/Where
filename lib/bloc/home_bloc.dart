import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:where/model/member.dart';
import 'package:where/service/firestore_service.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FireStoreService fireStoreService;
  final FirebaseAuth auth;
  StreamSubscription? locStream, memberStream;
  HomeBloc(this.fireStoreService, this.auth) : super(HomeInitial()) {
    on<HomeEvent>((event, emit) async {
      if (event is InitLocation) {
        await _handleInitLocation(emit);
      }

      if (event is MembersLoaded) {
        emit(HomeSuccess(currentP: event.currentP, members: event.members));
      }

      if (event is SignOutEvent) {
        await _signOut(emit);
      }
    });
  }

  Future<void> _handleInitLocation(Emitter emit) async {
    try {
      Position p = await _determinePosition();
      await _updateMember(p);

      await memberStream?.cancel();
      memberStream = fireStoreService.listenToMembers().listen(
        (event) async {
          List<MemberModel> list = [];
          for (final doc in event.docs) {
            final member = Member.fromJson(doc.data());
            final bitmap = await _handleMarkers(member);
            list.add(MemberModel(member, bitmap));
          }
          add(MembersLoaded(list, p));
        },
      );

      LocationSettings locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        //(Optional) Set foreground notification config to keep the app alive
        //when going to the background
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "app will continue to receive your location even when you aren't using it",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
        ),
      );

      await locStream?.cancel();
      locStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position? position) async {
        if (position != null) {
          await _updateMember(position);
        }
      });
    } catch (e) {
      emit(HomeFailed());
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location Service is not enabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        throw Exception("Location Permission is missing");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception(
          "Location permissions are permanently denied, we cannot request permissions.");
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<BitmapDescriptor> _handleMarkers(Member member) async {
    final File markerImageFile =
        await DefaultCacheManager().getSingleFile(member.url);
    final Uint8List markerImageBytes = await markerImageFile.readAsBytes();
    return BitmapDescriptor.fromBytes(markerImageBytes);
  }

  Future<void> _signOut(Emitter emit) async {
    await FirebaseAuth.instance.signOut();
    emit(HomeSignOut());
  }

  Future<void> _updateMember(Position p) async {
    if (auth.currentUser == null) {
      return;
    }
    Member member = Member(
      lat: p.latitude,
      lng: p.longitude,
      timestampInMs: p.timestamp?.millisecondsSinceEpoch ?? -1,
      name: auth.currentUser?.displayName ?? '',
      url: auth.currentUser?.photoURL ?? '',
      id: auth.currentUser?.uid ?? '',
    );

    await fireStoreService.updateMember(member);
  }
}

class MemberModel {
  Member member;
  BitmapDescriptor bitmapDescriptor;

  MemberModel(this.member, this.bitmapDescriptor);
}
