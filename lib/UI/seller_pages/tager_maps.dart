import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../../google maps/models/autocomplete_model.dart';
import '../../google maps/models/routes models/Locationinfomodel.dart';
import '../../google maps/models/routes_model.dart';
import '../../services/google_maps/google_maps_places_service.dart';
import '../../services/google_maps/location_service.dart';
import '../../services/google_maps/routes_service.dart';
import '../../providers/language_provider.dart';

class TagerMaps extends StatefulWidget {
  final LatLng? initialLocation;

  const TagerMaps({
    super.key,
    this.initialLocation,
  });

  @override
  State<TagerMaps> createState() => _TagerMapsState();
}

class _TagerMapsState extends State<TagerMaps> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  final LocationService locationService = LocationService();
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(32.0833, 36.1000), // Al-Zarqa, Jordan coordinates
    zoom: 15,
  );
  MapType _currentMapType = MapType.normal;
  bool _isDarkMode = false;
  bool isFirstCall = true;
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  late GoogleMapsPlacesService googleMapsPlacesService;
  List<AutocompleteModel> places = [];
  bool isSuggestionsVisible = false;
  late Uuid uuid;
  String? sessionToken;
  LatLng? currentLocation;
  late RoutesService routesService;
  Set<Polyline> polylines = {};
  LatLng? pickupLocationMaps;
  LatLng? dropoffLocationMaps;
  late TextEditingController pickupController;
  late TextEditingController dropoffController;
  bool _isInitialCameraMove = true;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    uuid = const Uuid();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    routesService = RoutesService();
    pickupController = TextEditingController();
    dropoffController = TextEditingController();
    googleMapsPlacesService = GoogleMapsPlacesService();
    
    // Initialize camera position with the stored location
    if (widget.initialLocation != null) {
      initialCameraPosition = CameraPosition(
        target: widget.initialLocation!,
        zoom: 17,
      );
      _updateAddressFromLatLng(widget.initialLocation!, true);
    }
    
    updateLocation();

    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('store_location'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Store Location'),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(TagerMaps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation && widget.initialLocation != null) {
      _moveToSelectedLocation(widget.initialLocation!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _toggleDarkMode() async {
    if (_isDarkMode) {
      _mapController.setMapStyle(null);
    } else {
      String darkMapStyle = await DefaultAssetBundle.of(context)
          .loadString('assets/googleMaps/dark.json');
      _mapController.setMapStyle(darkMapStyle);
    }
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<BitmapDescriptor> getCustomMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(96, 96)), // Size of the icon
      'assets/googleMaps/current_location4.png', // Path to the asset image
    );
  }

  void addCustomMarker() async {
    final BitmapDescriptor customIcon = await getCustomMarkerIcon();
    setState(() {
      _markers.clear(); // Clear existing markers
      _markers.add(
        Marker(
          markerId: const MarkerId('customMarker'),
          position: _selectedLocation ?? currentLocation ?? LatLng(32.0833, 36.1000),
          icon: customIcon, // Use the custom icon
        ),
      );
    });
  }

  void _onCameraMove(CameraPosition position) async {
    if (_isInitialCameraMove) {
      _isInitialCameraMove = false;
      return;
    }

    setState(() {
      _selectedLocation = position.target;
      isSuggestionsVisible = false;
    });

    // Update the marker position
    addCustomMarker();

    // Update the address in the text field
    _updateAddressFromLatLng(position.target, true);
  }

  void _updateAddressFromLatLng(LatLng latLng, bool isPickup) async {
    try {
      String address = await googleMapsPlacesService.getAddressFromLatLng(latLng);
      setState(() {
        pickupController.text = address;
        _selectedLocation = latLng;
      });
    } catch (e) {
      print("Failed to fetch address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(

      body: Stack(
        children: [
          GoogleMap(
            polylines: Set<Polyline>.of(polylines),
            initialCameraPosition: initialCameraPosition,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              updateLocation();
              addCustomMarker();
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: () {
              if (_selectedLocation != null) {
                _updateAddressFromLatLng(_selectedLocation!, true);
              }
            },
            mapType: _currentMapType,
            circles: {
              Circle(
                circleId: CircleId("myCircle"),
                center: _selectedLocation ?? currentLocation ?? LatLng(32.0833, 36.1000),
                radius: width * 0.24,
                strokeWidth: 2,
                strokeColor: Colors.black,
                fillColor: Colors.blue.withAlpha(50),
              ),
            },
            onTap: (LatLng location) {
              setState(() {
                _selectedLocation = location;
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: location,
                    infoWindow: const InfoWindow(title: 'Selected Location'),
                  ),
                );
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: height * 0.0,
            width: width,
            child: Container(
              height: height * 0.23,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xffF1E4CF), Color(0xfffaf1e6), Colors.white],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * 0.1),
                  bottomRight: Radius.circular(width * 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                children: [
                  SizedBox(height: height * 0.04),
                  Row(
                    children: [
                      Image.asset(
                          'assets/googleMaps/location_white.png',
                          height: height * 0.07,
                          width: width * 0.07,
                          color: const Color(0xff503636)
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Container(
                          width: width * 0.7,
                          child: TextField(
                            controller: pickupController,
                            onChanged: (value) {
                              setState(() {
                                _isUserTyping = true;
                                if (value.isEmpty) {
                                  places.clear();
                                  isSuggestionsVisible = false;
                                } else {
                                  fetchAutocompleteSuggestions();
                                }
                              });
                            },
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                              color: const Color(0xff503636),
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(width * 0.1),
                                borderSide: const BorderSide(color: Color(0xff503636)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(width * 0.1),
                                borderSide: const BorderSide(color: Color(0xff503636)),
                              ),
                              hintText: "Store Location",
                              hintStyle: GoogleFonts.roboto(
                                fontSize: width * 0.04,
                                color: const Color(0xff503636).withOpacity(0.7),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear, color: const Color(0xff503636)),
                                onPressed: () {
                                  setState(() {
                                    pickupController.clear();
                                    _selectedLocation = null;
                                    places.clear();
                                    isSuggestionsVisible = false;
                                    _isUserTyping = false;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(width * 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff503636),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(width * 0.08),
                      ),
                    ),
                    onPressed: _selectedLocation != null
                        ? () {
                            Navigator.pop(
                              context,
                              {
                                'storeLocation': _selectedLocation,
                              },
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: width * 0.055,
                    ),
                    label: Text(
                      languageProvider.translate('addressManagement.saveAddress'),
                      style: GoogleFonts.cairo(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: height * 0.12,
            left: width * 0.06,
            right: width * 0.06,
            child: AnimatedOpacity(
              opacity: isSuggestionsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                constraints: BoxConstraints(
                  maxHeight: isSuggestionsVisible ? height * 0.4 : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(width * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: places.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: height * 0.01),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        places[index].description ?? "لا يوجد تفاصيل",
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      onTap: () async {
                        var details = await googleMapsPlacesService.getPlaceDetails(
                            placeID: places[index].placeId.toString());

                        setState(() {
                          places.clear();
                          sessionToken = null;
                          isSuggestionsVisible = false;
                          pickupController.text = details.formattedAddress!;
                          _selectedLocation = LatLng(
                            details.geometry!.location!.lat!,
                            details.geometry!.location!.lng!,
                          );
                          _moveToSelectedLocation(_selectedLocation!);
                        });
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemCount: places.length,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: height * 0.1,
            left: width * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _toggleMapType,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.map, color: Colors.black),
                ),
                SizedBox(height: height * 0.02),
                FloatingActionButton(
                  onPressed: _toggleDarkMode,
                  backgroundColor: Colors.white,
                  child: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.black),
                ),
                SizedBox(height: height * 0.02),
                FloatingActionButton(
                  onPressed: updateCurrentLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateLocation() async {
    try {
      await locationService.checkAndRequestLocationService();
      await locationService.checkAndRequestLocationPermission();

      locationService.location.changeSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
        interval: 2000,
      );

      locationService.getRealtimeLocation((locationData) {
        if (locationData.latitude == null || locationData.longitude == null)
          return;

        setState(() {
          currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
          _markers.clear();
        });

        addCustomMarker();

        // Only move camera to current location if no initial location was provided
        if (isFirstCall && _mapController != null && widget.initialLocation == null) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: currentLocation!, zoom: 17),
            ),
          );
          isFirstCall = false;
        } else if (widget.initialLocation != null) {
          // Move to the stored location
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: widget.initialLocation!, zoom: 17),
            ),
          );
        }
      });
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  void updateCurrentLocation() {
    if (_mapController != null && currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation!, zoom: 17),
        ),
      );
    } else {
      print("Map controller not initialized or current location is null.");
    }
  }

  void showErrorDialog(dynamic e) {
    String errorMessage = "حدث خطأ أثناء تحديد الموقع";
    if (e is LocationServiceException) {
      errorMessage = "يرجى تفعيل خدمة الموقع ليعمل التطبيق بشكل صحيح";
    } else if (e is LocationPermissionException) {
      errorMessage = "يجب منح إذن الموقع لكي يعمل التطبيق بالشكل المطلوب";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          errorMessage,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void fetchAutocompleteSuggestions() async {
    if (!_isUserTyping) return;
    
    sessionToken ??= uuid.v4();
    String input = pickupController.text;

    if (input.isNotEmpty) {
      try {
        var suggestions = await googleMapsPlacesService.getAutocomplete(
          input: input,
          sessionToken: sessionToken!,
        );
        if (mounted) {
          setState(() {
            places = suggestions;
            isSuggestionsVisible = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        print("Error fetching suggestions: $e");
        if (mounted) {
          setState(() {
            places.clear();
            isSuggestionsVisible = false;
          });
        }
      }
    } else {
      setState(() {
        places.clear();
        isSuggestionsVisible = false;
      });
    }
  }

  Future<List<LatLng>> getRouteData(LatLng pickup, LatLng dropoff) async {
    while (currentLocation == null) {
      await Future.delayed(Duration(milliseconds: 500));
    }

    Locationinfomodel origin = Locationinfomodel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: pickup.latitude,
          longitude: pickup.longitude,
        ),
      ),
    );

    Locationinfomodel destination = Locationinfomodel(
      location: LocationModel(
        latLng: LatLngModel(
          latitude: dropoff.latitude,
          longitude: dropoff.longitude,
        ),
      ),
    );

    try {
      RoutesModel routes = await routesService.fetchRoutes(
          origin: origin, destination: destination);

      if (routes.routes.isEmpty) {
        print("Error: No routes found.");
        return [];
      }

      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints
          .decodePolyline(routes.routes.first.polyline.encodedPolyline);

      List<LatLng> points = result
          .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
          .toList();

      if (points.isEmpty) {
        print("Error: No points received for the polyline.");
      }

      return points;
    } catch (e) {
      print("Error fetching route: $e");
      return [];
    }
  }

  void displayRoute(List<LatLng> points, LatLng pickup, LatLng dropoff) {
    if (points.isEmpty) {
      print("No points received for the polyline.");
      return;
    }

    setState(() {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          width: 5,
          color: Colors.blue,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
      );
    });

    print("Updated polylines count: ${polylines.length}");
  }

  void clearRoute(bool isPickup) {
    setState(() {
      if (isPickup) {
        pickupController.clear();
        pickupLocation = null;
      } else {
        dropoffController.clear();
        dropoffLocation = null;
      }

      if (pickupLocation == null || dropoffLocation == null) {
        polylines.clear();
      }
    });
  }

  void saveLocations() {
    var width = MediaQuery.of(context).size.width;
    if (pickupLocationMaps != null && dropoffLocationMaps != null) {
      setState(() {
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("يرجى تحديد موقع التسليم والاستلام",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                ))),
      );
    }
  }

  void _moveToSelectedLocation(LatLng location) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 17),
        ),
      );
      setState(() {
        _selectedLocation = location;
      });

      // Update the marker position
      addCustomMarker();

      // Update the address in the text field
      _updateAddressFromLatLng(location, true);
    }
  }
}