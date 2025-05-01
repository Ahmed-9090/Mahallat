import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../google maps/models/autocomplete_model.dart';
import '../../services/google_maps/google_maps_places_service.dart';
import '../../services/google_maps/location_service.dart';
import '../../providers/language_provider.dart';

class AdressManagmentMaps extends StatefulWidget {
  const AdressManagmentMaps({super.key});

  @override
  State<AdressManagmentMaps> createState() => _AdressManagmentState();
}

class _AdressManagmentState extends State<AdressManagmentMaps> {
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(32.0833, 36.1000), // Al-Zarqa coordinates
    zoom: 15,
  );

  GoogleMapController? mapController;
  MapType _currentMapType = MapType.normal;
  bool _isDarkMode = false;
  Set<Marker> markers = {};
  late GoogleMapsPlacesService googleMapsPlacesService;
  List<AutocompleteModel> places = [];
  bool isSuggestionsVisible = false;
  late Uuid uuid;
  String? sessionToken;
  late TextEditingController addressController;
  LatLng? _selectedLocation;
  bool _isInitialCameraMove = true;
  bool _isUserTyping = false;
  bool _isLoading = true;
  LatLng? currentLocation;
  LocationService locationService = LocationService();
  bool isFirstCall = true;

  @override
  void initState() {
    uuid = const Uuid();
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    addressController = TextEditingController();
    googleMapsPlacesService = GoogleMapsPlacesService();
    _loadUserLocation();
    updateLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    addressController.dispose();
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
      mapController?.setMapStyle(null);
    } else {
      String darkMapStyle = await DefaultAssetBundle.of(context)
          .loadString('assets/googleMaps/dark.json');
      mapController?.setMapStyle(darkMapStyle);
    }
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<BitmapDescriptor> getCustomMarkerIcon() async {
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(96, 96)),
      'assets/googleMaps/current_location4.png',
    );
  }

  void addCustomMarker() async {
    final BitmapDescriptor customIcon = await getCustomMarkerIcon();
    setState(() {
      markers.clear();
      if (_selectedLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('customMarker'),
            position: _selectedLocation!,
            icon: customIcon,
          ),
        );
      }
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

    addCustomMarker();
    _updateAddressFromLatLng(position.target);
  }

  void _updateAddressFromLatLng(LatLng latLng) async {
    try {
      String address = await googleMapsPlacesService.getAddressFromLatLng(latLng);
      setState(() {
        addressController.text = address;
        _selectedLocation = latLng;
      });
    } catch (e) {
      print("Failed to fetch address: $e");
    }
  }

  Future<void> _saveUserLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<LanguageProvider>(context, listen: false).translate('addressManagement.selectLocation'),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'userLocation': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'location': addressController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<LanguageProvider>(context, listen: false).translate('addressManagement.saveSuccess'),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('addressManagement.saveError'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            markers: markers,
            onMapCreated: (controller) {
              mapController = controller;
              updateLocation();
              addCustomMarker();
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: () {
              if (_selectedLocation != null) {
                _updateAddressFromLatLng(_selectedLocation!);
              }
            },
            mapType: _currentMapType,
            circles: _selectedLocation != null ? {
              Circle(
                circleId: CircleId("myCircle"),
                center: _selectedLocation!,
                radius: width * 0.24,
                strokeWidth: 2,
                strokeColor: Colors.black,
                fillColor: Colors.blue.withAlpha(50),
              ),
            } : {},
          ),
          Positioned(
            top: height * 0.0,
            width: width,
            child: Container(
              height: height * 0.24,
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
                        color: const Color(0xff503636),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: Container(
                          width: width * 0.7,
                          child: TextField(
                            controller: addressController,
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
                              hintText: languageProvider.translate('addressManagement.enterAddress'),
                              hintStyle: GoogleFonts.roboto(
                                fontSize: width * 0.036,
                                color: const Color(0xff503636).withOpacity(0.7),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear, color: const Color(0xff503636)),
                                onPressed: () {
                                  setState(() {
                                    addressController.clear();
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
                    onPressed: _saveUserLocation,
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
                        places[index].description ?? languageProvider.translate('addressManagement.noDetails'),
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      onTap: () async {
                        var details = await googleMapsPlacesService.getPlaceDetails(
                            placeID: places[index].placeId.toString());

                        setState(() {
                          places.clear();
                          sessionToken = null;
                          isSuggestionsVisible = false;
                          addressController.text = details.formattedAddress!;
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
                    color: Colors.black,
                  ),
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

  void fetchAutocompleteSuggestions() async {
    if (!_isUserTyping) return;

    sessionToken ??= uuid.v4();
    String input = addressController.text;

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

  void _moveToSelectedLocation(LatLng location) async {
    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 17),
        ),
      );
      setState(() {
        _selectedLocation = location;
      });

      addCustomMarker();
      _updateAddressFromLatLng(location);
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()?['userLocation'] != null) {
          final locationData = doc.data()?['userLocation'];
          final storedLocation = LatLng(
            locationData['latitude'],
            locationData['longitude'],
          );
          
          setState(() {
            _selectedLocation = storedLocation;
            initialCameraPosition = CameraPosition(
              target: storedLocation,
              zoom: 15,
            );
            _isLoading = false;
          });

          if (doc.data()?['location'] != null) {
            addressController.text = doc.data()?['location'];
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user location: $e");
      setState(() {
        _isLoading = false;
      });
    }
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
          markers.clear();
        });

        addCustomMarker();

        if (isFirstCall && mapController != null) {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: currentLocation!, zoom: 17),
            ),
          );
          isFirstCall = false;
        }
      });
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  void updateCurrentLocation() {
    if (mapController != null && currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocation!, zoom: 17),
        ),
      );
    } else {
      print("Map controller not initialized or current location is null.");
    }
  }
}

