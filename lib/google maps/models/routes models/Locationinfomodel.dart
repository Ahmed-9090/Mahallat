class Locationinfomodel {
  LocationModel? location;

  Locationinfomodel({this.location});

  Locationinfomodel.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new LocationModel.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    return data;
  }
}

class LocationModel {
  LatLngModel? latLng;

  LocationModel({this.latLng});

  LocationModel.fromJson(Map<String, dynamic> json) {
    latLng =
    json['latLng'] != null ? new LatLngModel.fromJson(json['latLng']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.latLng != null) {
      data['latLng'] = this.latLng!.toJson();
    }
    return data;
  }
}

class LatLngModel {
  double? latitude;
  double? longitude;

  LatLngModel({this.latitude, this.longitude});

  LatLngModel.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    return data;
  }
}