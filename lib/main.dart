import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' as geo;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MapPage());
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location location = Location();
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Set<Polyline> polyline = {};

  void _onMapCreated(GoogleMapController mapController) {
    _controller.complete(mapController);
    _mapController = mapController;
  }

  _checkLocationPermission() async {
    bool locationServiceEnabled = await location.serviceEnabled();
    if (!locationServiceEnabled) {
      locationServiceEnabled = await location.requestService();
      if (!locationServiceEnabled) {
        return;
      }
    }

    PermissionStatus locationForAppStatus = await location.hasPermission();
    if (locationForAppStatus == PermissionStatus.denied) {
      await location.requestPermission();
      locationForAppStatus = await location.hasPermission();
      if (locationForAppStatus != PermissionStatus.granted) {
        return;
      }
    }
    LocationData locationData = await location.getLocation();
    _mapController.moveCamera(CameraUpdate.newLatLng(
        LatLng(locationData.latitude!, locationData.longitude!)));
  }

  Future<LatLng> _getCenter() async {
    final GoogleMapController controller = await _controller.future;
    LatLngBounds visibleRegion = await controller.getVisibleRegion();
    LatLng centerLatLng = LatLng(
      (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
      (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) /
          2,
    );
    return centerLatLng;
  }

  // Future _getLocationData() async {
  //   geo.Position position = await geo.Geolocator.getCurrentLocation(desiredAccuracy: geo.LocationAccuracy.high);
  // }

  // Future<geo.Position> _getLocationData() async {
  //   return geo.Geolocator.getCurrentPosition(
  //       desiredAccuracy: geo.LocationAccuracy.high);
  // }
  // getUserLocation() async {
  //   geo.Position currentLocation = await _getLocationData();
  //   setState(() {
  //     LatLng(currentLocation.latitude, currentLocation.longitude);
  //   });
  // }

  // late LatLng currentPosition;
  // Future _getUserLocation() async {
  //   var position = await geo.GeolocatorPlatform.instance
  //       .getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
  //   setState(() {
  //     currentPosition = LatLng(position.latitude, position.longitude);
  //   });
  // }

  void _reset() {
    setState(() {
      markers.clear();
      polyline.clear();
    });
  }

  void _addMarker() async {
    _reset();

    LatLng currentLocation =
        const LatLng(37.42206675977931, -122.0840898860863);
    // await _getUserLocation();

    markers.add(Marker(
        markerId: const MarkerId("start"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        position: currentLocation));

    LatLng pointerLocation = await _getCenter();

    markers.add(Marker(
        markerId: const MarkerId("finish"),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        position: pointerLocation));

    polyline.add(Polyline(
      polylineId: const PolylineId("polyline"),
      color: Colors.purple,
      width: 4,
      points: markers.map((marker) => marker.position).toList(),
    ));

    final LatLng southwest = LatLng(
      min(currentLocation.latitude, pointerLocation.latitude),
      min(currentLocation.longitude, pointerLocation.longitude),
    );
    final LatLng northeast = LatLng(
      max(currentLocation.latitude, pointerLocation.latitude),
      max(currentLocation.longitude, pointerLocation.longitude),
    );

    LatLngBounds bounds =
        LatLngBounds(southwest: southwest, northeast: northeast);

    await _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );

    setState(() {});
  }

  void moveCamera() async {
    LatLng currentLocation =
        const LatLng(37.42206675977931, -122.0840898860863);
    final LatLng southwest =
        LatLng(currentLocation.latitude, currentLocation.longitude);
    final LatLng northeast =
        LatLng(currentLocation.latitude, currentLocation.longitude);

    LatLngBounds bounds =
        LatLngBounds(southwest: southwest, northeast: northeast);

    await _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );

    setState(() {});
  }

  @override
  initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map page"),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: const CameraPosition(
              target: LatLng(55.751696, 37.618859),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            markers: markers,
            polylines: polyline,
          ),
          const Icon(
            Icons.push_pin_outlined,
            color: Colors.purple,
            size: 50.0,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _addMarker();
                    },
                    child: const Text('Проложить'),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _reset();
                      moveCamera();
                    },
                    child: const Text('Сброс'),
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
