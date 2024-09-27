import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals/globals.dart';
import 'classes/TreeView.dart';
import 'classes/Assets.dart';
import 'classes/Locations.dart';

List<TreeViewNode> gTreeChildren = [];
List<String> searchList = [];
List<TreeViewNode> searchResults = [];
List<String> searchMatchedNames = [];
bool searching = false;
late Future<bool> isTreeMounted;
late ListOfAssets? rawListOfAssets;
late LocationsList? rawListOfLocations;
late bool onlyEnergySensors;
late bool forceShowLoading;
late bool onlyCriticalSensors;

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key, required this.businessId});
  final String businessId;

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  @override
  void initState() {
    super.initState();
    rawListOfAssets = null;
    rawListOfLocations = null;
    isTreeMounted = fetchIfNullAndMountTree(widget.businessId);
    forceShowLoading = false;
    gTreeChildren = [];
    searchResults = [];
    searchMatchedNames = [];
    onlyEnergySensors = false;
    onlyCriticalSensors = false;
    searchList = [];
    searching = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  //TODO: Open all nodes in search:
  List<TreeViewNode> getMatchNodesOnMainTree(String query) {
    List<TreeViewNode> queryResult = [];
    for (var childNode in gTreeChildren) {
      if (isNodeNameOnSubTree(query, childNode)) {
        queryResult.add(childNode);
      }
    }
    return queryResult;
  }

  void cleanSearchResultsTreeView() {
    String? getNameAssociatedWithSearchedNoded(TreeViewNode node) {
      for (var name in searchMatchedNames) {
        if (isNodeNameOnSubTree(name, node)) {
          return name;
        }
      }
      return null;
    }

    for (var node in searchResults) {
      _cleanSubTree(node, getNameAssociatedWithSearchedNoded(node)!);
    }
    return;
  }

  void _cleanSubTree(TreeViewNode node, String name) {
    if (node.value == name) {
      return;
    }
    if (!isNodeNameOnSubTree(name, node) || node.children == null) {
      throw Exception("Invalid Tree to be cleaned");
    }
    if (node.children!.isEmpty) {
      throw Exception("Invalid Tree to be cleaned");
    }

    final children = List<TreeViewNode>.from(node.children!);
    for (var (index, child) in node.children!.indexed) {
      if (!isNodeNameOnSubTree(name, child)) {
        children.removeAt(index);
      }
    }
    node.children = children;

    for (var childNode in node.children!) {
      _cleanSubTree(childNode, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => {
                    Navigator.of(context).pop(),
                  },
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xffffffff),
              )),
          backgroundColor: const Color(0xff17192D),
          title: const Text(
            "Assets",
            style: TextStyle(color: Color(0xffffffff)),
          ),
          centerTitle: true,
        ),
        body: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: 40,
                  child: SearchBar(
                    onChanged: (query) async {
                      if (query == "") {
                        searching = false;
                        setState(() {});
                        return;
                      }
                      searching = true;
                      setState(() {});

                      searchMatchedNames = getMatchesOnListOfNames(query);
                      searchResults = [];
                      if (searchMatchedNames.isEmpty) {
                        searchResults = [
                          TreeViewNode(
                              isRoot: false,
                              value: "Nem um resultado encontrado")
                        ];
                        setState(() {});
                        return;
                      }

                      for (var queryResult in searchMatchedNames) {
                        searchResults
                            .addAll(getMatchNodesOnMainTree(queryResult));
                      }

                      cleanSearchResultsTreeView();

                      setState(() {});
                    },
                    elevation: MaterialStateProperty.all<double>(0),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero)),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xffEAEFF3)),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.only(left: 20)),
                    leading: const Icon(Icons.search_rounded),
                    hintText: "Buscar Ativo ou Local",
                  )),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () async {
                          onlyEnergySensors = !onlyEnergySensors;
                          gTreeChildren = [];
                          forceShowLoading = true;
                          setState(() {});
                          await fetchIfNullAndMountTree(widget.businessId);
                          forceShowLoading = false;
                          setState(() {});
                          return;
                        },
                        style: underSearchBarButtonStyle,
                        child: Row(children: [
                          Image.asset(
                            "assets/energy_icon.png",
                            color: onlyEnergySensors
                                ? const Color(0xffffff00)
                                : null,
                          ),
                          const Text(" Sensor de Energia"),
                        ]),
                      )),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: () async {
                        onlyCriticalSensors = !onlyCriticalSensors;
                        gTreeChildren = [];
                        forceShowLoading = true;
                        setState(() {});
                        await fetchIfNullAndMountTree(widget.businessId);
                        forceShowLoading = false;
                        setState(() {});
                        return;
                      },
                      style: underSearchBarButtonStyle,
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/alert_icon.png",
                            color: onlyCriticalSensors
                                ? const Color(0xffff0000)
                                : null,
                          ),
                          const Text(" Crítico"),
                        ],
                      ))
                ],
              ),
            ]),
          ),
          const Divider(
            height: 0.2,
            thickness: 2,
          ),
          const SizedBox(
            height: 10,
          ),
          FutureBuilder(
              future: isTreeMounted,
              builder: (context, snap) {
                if (snap.hasData && snap.data != null) {
                  if (forceShowLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (searching) {
                    return SizedBox(
                      height: 3 * (MediaQuery.of(context).size.height) / 4,
                      child: TreeView(
                          rootNode: TreeViewNode(
                              children: searchResults, isRoot: true)),
                    );
                  }
                  return SizedBox(
                    height: 3 * (MediaQuery.of(context).size.height) / 4,
                    child: TreeView(
                        rootNode: TreeViewNode(
                            children: gTreeChildren, isRoot: true)),
                  );
                }
                return const CircularProgressIndicator();
              }),
        ]));
  }
}

Future<LocationsList?> fetchLocations(String businesssId) async {
  final client = http.Client();
  final response =
      await client.get(Uri.http(apiUri, "companies/$businesssId/locations"));

  if (response.statusCode != 200) {
    return null;
  }

  try {
    return LocationsList.fromJson(response.body);
  } catch (err) {
    throw Exception(
        "There is something wrong with the api -> ${err.toString()}");
  }
}

Future<ListOfAssets?> fetchAssets(String businesssId) async {
  final client = http.Client();
  final response =
      await client.get(Uri.http(apiUri, "companies/$businesssId/assets"));

  if (response.statusCode != 200) {
    return null;
  }

  try {
    return ListOfAssets.fromJson(response.body);
  } catch (err) {
    throw Exception(
        "There is something wrong with the api -> ${err.toString()}");
  }
}

List<String> getMatchesOnListOfNames(String query) {
  query = query.toLowerCase();
  return searchList
      .where((element) => element.toLowerCase().contains(query))
      .toList();
}

bool isNodeNameOnSubTree(String name, TreeViewNode node) {
  if (node.value == name) {
    return true;
  }
  if (node.children == null) {
    return false;
  }

  for (var subNode in node.children!) {
    if (isNodeNameOnSubTree(name, subNode)) {
      return true;
    }
  }

  return false;
}

// TODO: Could've been better implemented: Way too many for loops that
// likely did not had to exist;
Future<bool> fetchIfNullAndMountTree(String businesssId) async {
  try {
    rawListOfAssets =
        rawListOfAssets ?? await Isolate.run(() => fetchAssets(businesssId));
    rawListOfLocations = rawListOfLocations ??
        await Isolate.run(() => fetchLocations(businesssId));
  } catch (_) {
    return false;
  }

  Map<String, int> assetIdToListIndex = {}; //
  Map<String, int> locationIdToListIndex = {}; //

  for (var index = 0; index < rawListOfAssets!.array.length; index++) {
    final asset = rawListOfAssets!.array[index];
    if (!searchList.contains(asset.name)) {
      searchList.add(asset.name);
    }
    assetIdToListIndex.putIfAbsent(asset.id, () => index);
  }

  for (var index = 0; index < rawListOfLocations!.array.length; index++) {
    final location = rawListOfLocations!.array[index];
    if (searchList.contains(location.name)) {
      searchList.add(location.name);
    }
    locationIdToListIndex.putIfAbsent(location.id, () => index);
  }

  for (var asset in rawListOfAssets!.array) {
    if (asset.parentId != null) {
      final parent =
          rawListOfAssets!.array[assetIdToListIndex[asset.parentId]!];
      if (!parent.subAssetsIds.contains(asset.id)) {
        parent.subAssetsIds.add(asset.id);
      }
    }

    if (asset.locationId != null) {
      final location =
          rawListOfLocations!.array[locationIdToListIndex[asset.locationId]!];
      if (!location.subAssetsIds.contains(asset.id)) {
        location.subAssetsIds.add(asset.id);
      }
    }
  }

  for (var location in rawListOfLocations!.array) {
    if (location.parentId != null) {
      final parent =
          rawListOfLocations!.array[locationIdToListIndex[location.parentId]!];
      if (!parent.subLocationsIds.contains(location.id)) {
        parent.subLocationsIds.add(location.id);
      }
    }
  }

  for (var location in rawListOfLocations!.array) {
    if (location.parentId == null) {
      if (((!onlyCriticalSensors) ||
              (onlyCriticalSensors &&
                  isCriticalSensorOnSubTreeOfLocations(
                      location, locationIdToListIndex, assetIdToListIndex))) &&
          ((!onlyEnergySensors) ||
              (onlyEnergySensors &&
                  isEnergySensorOnSubTreeOfLocations(
                      location, assetIdToListIndex, locationIdToListIndex)))) {
        final locationSubTree = mountSubTreeFromLocation(
            location, locationIdToListIndex, assetIdToListIndex);
        if (locationSubTree.children == null) {
          continue;
        }
        if (locationSubTree.children!.isEmpty) {
          continue;
        }
        gTreeChildren.add(locationSubTree);
      }
    }
  }

  for (var asset in rawListOfAssets!.array) {
    if (asset.parentId == null && asset.locationId == null) {
      var subTree = mountSubTreeOfAssets(asset, assetIdToListIndex);
      if (subTree == null) {
        continue;
      }
      gTreeChildren.add(subTree);
    }
  }

  return true;
}

bool isEnergySensorOnSubTreeOfAssets(
    Asset asset, Map<String, int> assetIdToListIndex) {
  if (asset.sensorType == "energy") {
    return true;
  }

  if (asset.subAssetsIds.isEmpty) {
    return false;
  }

  for (var subAssetId in asset.subAssetsIds) {
    if (isEnergySensorOnSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subAssetId]!],
        assetIdToListIndex)) {
      return true;
    }
  }
  return false;
}

bool isEnergySensorOnSubTreeOfLocations(
    Location location,
    Map<String, int> assetIdToListIndex,
    Map<String, int> locationIdToListIndex) {
  if (location.subAssetsIds.isEmpty && location.subLocationsIds.isEmpty) {
    return false;
  }

  for (var subLocationId in location.subLocationsIds) {
    if (isEnergySensorOnSubTreeOfLocations(
        rawListOfLocations!.array[locationIdToListIndex[subLocationId]!],
        assetIdToListIndex,
        locationIdToListIndex)) {
      return true;
    }
  }

  for (var subAssetId in location.subAssetsIds) {
    if (isEnergySensorOnSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subAssetId]!],
        assetIdToListIndex)) {
      return true;
    }
  }

  return false;
}

bool isCriticalSensorOnSubTreeOfLocations(
    Location location,
    Map<String, int> locationIdToListIndex,
    Map<String, int> assetIdToListIndex) {
  if (location.subAssetsIds.isEmpty && location.subLocationsIds.isEmpty) {
    return false;
  }

  for (var subLocationId in location.subLocationsIds) {
    if (isCriticalSensorOnSubTreeOfLocations(
        rawListOfLocations!.array[locationIdToListIndex[subLocationId]!],
        locationIdToListIndex,
        assetIdToListIndex)) {
      return true;
    }
  }

  for (var subAssetId in location.subAssetsIds) {
    if (isCriticalSensorOnSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subAssetId]!],
        assetIdToListIndex)) {
      return true;
    }
  }
  return false;
}

bool isCriticalSensorOnSubTreeOfAssets(
    Asset asset, Map<String, int> assetIdToListIndex) {
  if (asset.getAssetStatus() == AssetStatus.alert) {
    return true;
  }
  if (asset.subAssetsIds.isEmpty) {
    return false;
  }

  for (var subAssetId in asset.subAssetsIds) {
    if (isCriticalSensorOnSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subAssetId]!],
        assetIdToListIndex)) {
      return true;
    }
  }
  return false;
}

TreeViewNode? mountSubTreeOfAssets(
    Asset asset, Map<String, int> assetIdToListIndex) {
  if ((asset.subAssetsIds.isEmpty &&
          onlyCriticalSensors &&
          asset.getAssetStatus() != AssetStatus.alert) ||
      asset.subAssetsIds.isEmpty &&
          onlyEnergySensors &&
          asset.sensorType != "energy") {
    return null;
  }

  if (asset.subAssetsIds.isEmpty) {
    return TreeViewNode(value: asset.name, leadingIcon: asset.getAssetIcon());
  }

  List<TreeViewNode> children = [];

  for (var subassetId in asset.subAssetsIds) {
    var subTree = mountSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subassetId]!],
        assetIdToListIndex);
    if (subTree == null) {
      continue;
    }
    children.add(subTree);
  }

  return TreeViewNode(
      value: asset.name, children: children, leadingIcon: asset.getAssetIcon());
}

TreeViewNode mountSubTreeFromLocation(
    Location location,
    Map<String, int> locationIdToListIndex,
    Map<String, int> assetIdToListIndex) {
  if (location.subLocationsIds.isEmpty && location.subAssetsIds.isEmpty) {
    return TreeViewNode(
        value: location.name,
        leadingIcon: Image.asset("assets/location_icon.png"));
  }

  List<TreeViewNode> children = [];

  for (var subLocationId in location.subLocationsIds) {
    var _location =
        rawListOfLocations!.array[locationIdToListIndex[subLocationId]!];
    final hasCriticalSensor = isCriticalSensorOnSubTreeOfLocations(
        _location, locationIdToListIndex, assetIdToListIndex);
    final hasEnergySensor = isEnergySensorOnSubTreeOfLocations(
        _location, assetIdToListIndex, locationIdToListIndex);

    if (((!onlyCriticalSensors) ||
            (onlyCriticalSensors && hasCriticalSensor)) &&
        ((!onlyEnergySensors) || (onlyEnergySensors && hasEnergySensor))) {
      var subTree = mountSubTreeFromLocation(
          _location, locationIdToListIndex, assetIdToListIndex);
      if (subTree.children == null) {
        continue;
      }
      if (subTree.children!.isEmpty &&
          (onlyEnergySensors || onlyCriticalSensors)) {
        continue;
      }

      children.add(subTree);
    }
  }

  for (var subAssetId in location.subAssetsIds) {
    var subTree = mountSubTreeOfAssets(
        rawListOfAssets!.array[assetIdToListIndex[subAssetId]!],
        assetIdToListIndex);

    if (subTree == null) {
      continue;
    }

    children.add(subTree);
  }

  return TreeViewNode(
      value: location.name,
      children: children,
      leadingIcon: Image.asset("assets/location_icon.png"));
}
