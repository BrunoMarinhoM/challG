import 'dart:convert';

class Location {
  final String id;
  final String name;
  final String? parentId;
  List<String> subLocationsIds;
  List<String> subAssetsIds;

  Location({
    required this.id,
    required this.name,
    this.parentId,
    required this.subLocationsIds,
    required this.subAssetsIds,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey("id") ||
        !json.containsKey("name") ||
        !json.containsKey("parentId")) {
      throw Exception("Invalid Json");
    }
    List<String> subLocationsIds = [];
    List<String> subAssetsIds = [];

    return Location(
      id: json["id"],
      name: json["name"],
      parentId: json["parentId"],
      subLocationsIds: subLocationsIds,
      subAssetsIds: subAssetsIds,
    );
  }
}

class LocationsList {
  final List<Location> array;
  final int length;

  LocationsList({required this.array, required this.length});

  factory LocationsList.fromJson(String jsonString) {
    List<Location> array = [];

    try {
      final json = jsonDecode(jsonString);

      for (var item in json) {
        array.add(Location.fromJson(item));
      }

      return LocationsList(array: array, length: array.length);
    } catch (err) {
      throw Exception("Invalid Json");
    }
  }
}
