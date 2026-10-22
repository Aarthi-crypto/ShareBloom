import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {

  /// GET DEVICE LOCATION
  static Future<Position?> getCurrentLocation() async {

    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// GET CITY FROM LAT/LNG (OpenStreetMap)
  static Future<String?> getCityFromCoordinates(
      double lat, double lng) async {

    final url =
        "https://nominatim.openstreetmap.org/reverse"
        "?lat=$lat&lon=$lng&format=json";

    final response = await http.get(
      Uri.parse(url),
      headers: {"User-Agent": "share_bloom_app"},
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    return data["address"]?["city"] ??
        data["address"]?["town"] ??
        data["address"]?["village"];
  }

  /// INTERNAL SEARCH HELPER
  static Future<Map<String, double>?> _search(
      String query) async {

    final url =
        "https://nominatim.openstreetmap.org/search"
        "?q=${Uri.encodeComponent(query)}"
        "&format=json&limit=1";

    final response = await http.get(
      Uri.parse(url),
      headers: {"User-Agent": "share_bloom_app"},
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    if (data.isEmpty) return null;

    return {
      "lat": double.parse(data[0]["lat"]),
      "lng": double.parse(data[0]["lon"]),
    };
  }

  /// ADDRESS → COORDINATES (Improved Accuracy)
  static Future<Map<String, double>?> getCoordinates(
      String fullAddress) async {

    /// 1️⃣ Try full address
    var result = await _search(fullAddress);
    if (result != null) return result;

    /// 2️⃣ Remove landmark if present
    final parts = fullAddress.split(",");
    if (parts.length >= 2) {

      final addressCity =
          "${parts[0]}, ${parts.last}";

      result = await _search(addressCity);
      if (result != null) return result;
    }

    /// 3️⃣ Try only city
    if (parts.isNotEmpty) {

      result = await _search(parts.last.trim());
      if (result != null) return result;
    }

    /// 4️⃣ FINAL FALLBACK → DEVICE GPS
    final pos = await getCurrentLocation();
    if (pos != null) {
      return {
        "lat": pos.latitude,
        "lng": pos.longitude,
      };
    }

    return null;
  }

  /// DISTANCE BETWEEN USERS (KM)
  static double distanceKm(
      double lat1,
      double lng1,
      double lat2,
      double lng2) {

    return Geolocator.distanceBetween(
        lat1, lng1, lat2, lng2) /
        1000;
  }
}