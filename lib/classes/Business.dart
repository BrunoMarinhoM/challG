import 'dart:convert';

class Business {
  final String name;
  final String id;

  Business({required this.name, required this.id});

  factory Business.fromJson(Map<String, dynamic> json) {
    try {
      final bName = json["name"];
      final bId = json["id"];

      if (bName == null || bId == null) {
        throw Exception("Invalid json -> $json");
      }

      return Business(name: bName, id: bId);
    } catch (err) {
      throw Exception("Invalid json -> ${err.toString()}");
    }
  }

  getName() {
    return name;
  }

  getId() {
    return id;
  }
}

class ListOfBusiness {
  int length;
  List<Business>? list;

  ListOfBusiness({this.length = 0, this.list});

  factory ListOfBusiness.fromJson(String json) {
    try {
      List<dynamic> decodedJson = jsonDecode(json);
      List<Business> list = [];

      for (var businessJson in decodedJson) {
        list.add(Business.fromJson(businessJson));
      }

      return ListOfBusiness(list: list, length: list.length);
    } catch (err) {
      throw Exception("Invalid json -> ${err.toString()}");
    }
  }

  getAt(int index) {
    if (index >= length || index < 0) {
      throw Exception("Invalid Index");
    }
    if (list == null) {
      throw Exception("List hasn't been propertly initialized");
    }

    return list![index];
  }
}
