import 'dart:convert';
import 'package:flutter/material.dart';

enum AssetType { componentOrSensor, mainAsset }

enum AssetStatus { operating, alert }

class Asset {
  final String id;
  String name;
  String? locationId;
  String? parentId;
  String? sensorId;
  String? gatewayId;
  String? sensorType;
  String? status;
  List<String> subAssetsIds;

  Asset({
    required this.id,
    required this.subAssetsIds,
    required this.name,
    this.locationId,
    this.parentId,
    this.sensorId,
    this.gatewayId,
    this.sensorType,
    this.status,
  });

  getAssetType() {
    if (sensorType != null || sensorId != null) {
      return AssetType.componentOrSensor;
    }
    return AssetType.mainAsset;
  }

  getAssetStatus() {
    if (getAssetType() == AssetType.mainAsset) {
      return null;
    }

    return status == "alert" ? AssetStatus.alert : AssetStatus.operating;
  }

  getAssetIcon() {
    return getAssetType() == AssetType.componentOrSensor
        ? Image.asset("assets/component_icon.png")
        : Image.asset("assets/asset_icon.png");
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty || !json.containsKey("id") || !json.containsKey("name")) {
      throw Exception("Invalid Json");
    }

    List<String> subAssets = [];

    final asset =
        Asset(id: json["id"], name: json["name"], subAssetsIds: subAssets);

    if (json.containsKey("locationId")) {
      asset.locationId = json["locationId"];
    }

    if (json.containsKey("parentId")) {
      asset.parentId = json["parentId"];
    }

    if (json.containsKey("sensorId")) {
      asset.sensorId = json["sensorId"];
    }

    if (json.containsKey("gatewayId")) {
      asset.gatewayId = json["gatewayId"];
    }

    if (json.containsKey("sensorType")) {
      asset.sensorType = json["sensorType"];
    }

    if (json.containsKey("status")) {
      asset.status = json["status"];
    }

    return asset;
  }
}

class ListOfAssets {
  final List<Asset> array;
  int length;

  ListOfAssets({required this.array, this.length = 0});

  static Future<ListOfAssets> fromJson(String json) async {
    try {
      List<dynamic> decodedJson = jsonDecode(json);
      List<Asset> list = [];

      for (var businessJson in decodedJson) {
        list.add(Asset.fromJson(businessJson));
      }

      return ListOfAssets(array: list, length: list.length);
    } catch (err) {
      throw Exception("Invalid json -> ${err.toString()}");
    }
  }
}
