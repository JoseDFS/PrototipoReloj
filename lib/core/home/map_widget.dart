import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../../constants/app_constants.dart';
import '../../helpers/shared_prefs.dart';
import '../../main.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final LatLng _currentLocation =
      LatLng(13.694712686271076, -89.24192016538022);
  final _polyline = <Polyline>[];
  MapController? mapController;

  bool _isInside = false;
  Location location = Location();
  bool _serviceEnabled = false;

  _onMapCreated(MapController controller) {
    mapController = controller;
  }

  _checkGpsAndInside() async {
    var checking = false;
    try {
      checking = await location.serviceEnabled();
    } catch (e) {
      debugPrint(e.toString());
    }
    var checkInside = false;
    if (_currentLocation.latitude < 13.694476847076139 ||
        _currentLocation.latitude > 13.69478500152378 ||
        _currentLocation.longitude < -89.24198185617077 ||
        _currentLocation.longitude > -89.24185512180274) {
      checkInside = false;
    } else {
      checkInside = true;
    }
    if (checking) {
      location.onLocationChanged.listen((event) {
        setState(() {
          _currentLocation.latitude = event.latitude!;
          _currentLocation.longitude = event.longitude!;
        });
      });
    }
    if (checking != _serviceEnabled || checkInside != _isInside) {
      _serviceEnabled = checking;
      _isInside = checkInside;
      setState(() {});
    }
  }

  initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations
    Location _location = Location();
    bool? _serviceEnabled;
    PermissionStatus? _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
    }

    // Get the current user location
    LocationData _locationData = await _location.getLocation();
    _currentLocation.latitude = _locationData.latitude!;
    _currentLocation.longitude = _locationData.longitude!;
    // Store the user location in sharedPreferences
    sharedPreferences.setDouble('latitude', _locationData.latitude!);
    sharedPreferences.setDouble('longitude', _locationData.longitude!);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initializeLocationAndSave();
    _checkGpsAndInside();
    return Stack(
      children: [
        //Add MapboxMap here and enable user location
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            nePanBoundary: LatLng(13.695114003209238, -89.24144809662312),
            swPanBoundary: LatLng(13.694082043984372, -89.24233322554271),
            onMapCreated: _onMapCreated,
            maxZoom: 19,
            zoom: 18,
            minZoom: 16.8,
            center: LatLng(13.694108103616491, -89.24171631750784),
          ),
          nonRotatedLayers: [
            TileLayerOptions(
              maxZoom: 19,
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            PolylineLayerOptions(
              polylines: [
                Polyline(
                  points: constants.boundaries,
                  strokeWidth: 5,
                  color: Colors.blue,
                ),
              ],
            ),
            PolylineLayerOptions(polylines: _polyline),
            MarkerLayerOptions(
              markers: [
                Marker(
                  point: _currentLocation,
                  builder: (_) {
                    return const _MyLocationMarker();
                  },
                )
              ],
            ),
          ],
        ),
        //Message if inside Gps is activated
        if (!_serviceEnabled)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _isInside ? Colors.green[300] : Colors.red[300],
              ),
              child: const Center(
                child: Text(
                  "El GPS está desactivado!",
                ),
              ),
            ),
          ),
        //Message if inside of the area
        Positioned(
          bottom: 25,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _isInside ? Colors.green[300] : Colors.red[300],
            ),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
                child: Text(
                  "Te encuentras ${_isInside ? "dentro" : "fuera"} del area",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.orange,
            blurRadius: 2,
            offset: Offset(0, 2),
          )
        ],
      ),
      width: 32,
      height: 32,
    );
  }
}
