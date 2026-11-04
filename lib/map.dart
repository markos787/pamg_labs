import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'login.dart';

import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'dart:io';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

//----------------------------------------------------------

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool showOrtofoto = false;
  final MapController mapController = MapController();
  StreamSubscription<Position>? positionStream;
  List<Position> routePoints = [];
  bool isMeasuring = false;

  Future<void> startMeasurement() async {

    if (isMeasuring) {
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokalizacja telefonu jest wyłączona')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak uprawnień do udostępnienia lokalizacji'))
      );
      return;
    }

    routePoints.clear();
    setState(() {
      isMeasuring = true;
    });

    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
    );

    bool firstPosition = true;

    positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings).listen(Position position) {
        if (!isMeasuring){
          return;
        }
        setState(() {
          routePoints.add(position);
        });
        if (firstPosition) {
          mapController.move(
            LatLng(position.latitude, position.longitude),
            17);
            firstPosition = false;
        }
        print(
          'Pozycja: '
          '${position.latitude}'
          '${position.longitude}'
          '${position.timestamp}'
        );
      };
  }
}