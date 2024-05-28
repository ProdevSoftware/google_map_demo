import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_demo/presentation/home/component/address_search_view.dart';
import 'package:google_map_demo/presentation/home/model/address_detail_model.dart';
import 'package:google_map_demo/utils/api_key_const.dart';
import 'package:google_map_demo/utils/image_const.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_webservice/places.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  LatLng? _currentPositionOfUser;
  LatLng? targetPosition;
  bool _isLoading = true;
  CameraPosition initialPosition =
      CameraPosition(target: LatLng(34.32, 38.32), zoom: 16.0);
  String selectedAddress = '';
  final Set<Marker> _currentLocationMarkers = {};
  final Set<Marker> _tappedMarkers = {};
  final Set<Polyline> _polyLines = {};

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await getLocation();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
        visible: !_isLoading,
        replacement: const Center(
          child: CircularProgressIndicator(),
        ),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped,
              mapType: MapType.normal,
              initialCameraPosition: initialPosition,
              markers: {
                ..._currentLocationMarkers,
                ..._tappedMarkers,
              },
              polylines: _polyLines,
            ),
            Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              SvgConst.location,
                              height: 20,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Your location',
                              style: TextStyle(color: Colors.blue),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap:
                              selectedAddress.isNotEmpty ? null : onSearchEvent,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                  child: Text(
                                selectedAddress.isNotEmpty
                                    ? selectedAddress
                                    : 'Search',
                                style: const TextStyle(color: Colors.black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                              InkWell(
                                  onTap: onSearchEvent,
                                  child: const Icon(Icons.search_rounded)),
                              Visibility(
                                visible: selectedAddress.isNotEmpty,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: InkWell(
                                      onTap: clearTapPosition,
                                      child: const Icon(Icons.clear)),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  getLocation() async {
    _currentLocationMarkers.clear();
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      double lat = position.latitude;
      double long = position.longitude;

      LatLng location = LatLng(lat, long);
      initialPosition = CameraPosition(target: location, zoom: 16.0);
      List<Placemark> placeMarks = await placemarkFromCoordinates(lat, long);
      String address = placeMarks.isNotEmpty
          ? '${placeMarks[0].name!}, ${placeMarks[0].street!}, ${placeMarks[0].subLocality!}, ${placeMarks[0].locality!}'
          : 'Unknown';

      final Uint8List? markerIcon =
          await getBytesFromAsset(ImageConst.location, 60);

      BitmapDescriptor currentLocationMarker = markerIcon != null
          ? BitmapDescriptor.fromBytes(markerIcon)
          : await BitmapDescriptor.fromAssetImage(
              const ImageConfiguration(),
              ImageConst.location,
            );

      setState(() {
        _currentPositionOfUser = location;
        _isLoading = false;
        _currentLocationMarkers.add(
          Marker(
              markerId: const MarkerId('currentLocationOfUser'),
              position: location,
              icon: currentLocationMarker,
              infoWindow: InfoWindow(title: address)),
        );
      });
    } else {
      await getLocation();
    }
  }

  void _onMapTapped(LatLng tappedPosition) async {
    List<Placemark> placeMarks = await placemarkFromCoordinates(
        tappedPosition.latitude, tappedPosition.longitude);

    String tappedAddress = placeMarks.isNotEmpty
        ? '${placeMarks[0].name!}, ${placeMarks[0].street!}, ${placeMarks[0].subLocality!}, ${placeMarks[0].locality!}'
        : 'Unknown';

    // setState(() {
    _tappedMarkers.clear();
    _tappedMarkers.add(
      Marker(
        markerId: MarkerId(tappedPosition.toString()),
        position: tappedPosition,
        infoWindow: InfoWindow(
          title: tappedAddress,
        ),
      ),
    );
    // });
    selectedAddress = tappedAddress;
    setState(() {});

    _drawPolyline(_currentPositionOfUser!, tappedPosition);
  }

  void _drawPolyline(LatLng from, LatLng to) async {
    _polyLines.clear();
    double originLatitude = from.latitude;
    double originLongitude = from.longitude;
    double destLatitude = to.latitude;
    double destLongitude = to.longitude;
    PolylineResult results = await PolylinePoints().getRouteBetweenCoordinates(
       ApiKeyConst.mapApiKey,
      PointLatLng(originLatitude, originLongitude),
      PointLatLng(destLatitude, destLongitude),
    );

    _polyLines.add(
      Polyline(
        polylineId: const PolylineId('start'),
        color: Colors.grey,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        width: 8,
        patterns: [
          PatternItem.gap(7),
          PatternItem.dot,
          PatternItem.gap(7),
        ],
        points: [
          LatLng(originLatitude, originLongitude),
          LatLng(results.points.first.latitude, results.points.first.longitude),
        ],
      ),
    );

    _polyLines.add(
      Polyline(
        jointType: JointType.bevel,
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        width: 5,
        points: results.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(),
      ),
    );

    _polyLines.add(
      Polyline(
        polylineId: const PolylineId('end'),
        color: Colors.grey,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        width: 8,
        patterns: [
          PatternItem.gap(7),
          PatternItem.dot,
          PatternItem.gap(7),
        ],
        points: [
          LatLng(results.points.last.latitude, results.points.last.longitude),
          LatLng(destLatitude, destLongitude),
        ],
      ),
    );
    setState(() {});
  }

  Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  setPosition(LatLng tappedPosition, String tappedAddress) {
    _tappedMarkers.clear();
    _tappedMarkers.add(
      Marker(
        markerId: MarkerId(tappedPosition.toString()),
        position: tappedPosition,
        infoWindow: InfoWindow(
          title: tappedAddress,
        ),
      ),
    );
    initialPosition = CameraPosition(target: tappedPosition, zoom: 16.0);
    setState(() {});
    _drawPolyline(_currentPositionOfUser!, tappedPosition);
  }

  clearTapPosition() {
    _tappedMarkers.clear();
    _polyLines.clear();
    selectedAddress = '';
    targetPosition = null;
    initialPosition = CameraPosition(
        target: _currentPositionOfUser ?? const LatLng(10, 10), zoom: 16.0);
    setState(() {});
  }

  onSearchEvent() async {
    final sessionToken = const Uuid().v4();
    final Suggestion? result = await showSearch(
      context: context,
      delegate: AddressSearch(sessionToken),
    );
    if (result != null) {
      GoogleMapsPlaces places = GoogleMapsPlaces(
        apiKey: ApiKeyConst.mapApiKey,
      );
      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(result.placeId);
      List<Placemark> placeMarks = await placemarkFromCoordinates(
          detail.result.geometry?.location.lat ?? 0,
          detail.result.geometry?.location.lng ?? 0);
      String tappedAddress = placeMarks.isNotEmpty
          ? '${placeMarks[0].name!}, ${placeMarks[0].street!}, ${placeMarks[0].subLocality!}, ${placeMarks[0].locality!}'
          : 'Unknown';
      selectedAddress = detail.result.formattedAddress ?? '';
      setPosition(
          LatLng(detail.result.geometry?.location.lat ?? 0,
              detail.result.geometry?.location.lng ?? 0),
          tappedAddress);
    }
  }
}
