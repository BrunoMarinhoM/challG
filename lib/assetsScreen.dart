import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals/globals.dart';
import 'classes/TreeView.dart';
import 'classes/Assets.dart';
import 'classes/Locations.dart';

const expandChildrenOnReady = true;
const kDebugMode = true;
List<TreeViewNode> gTreeChildren = [];

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  late Future<ListOfAssets?> listOfAssets;
  late Future<Widget> mountedTree;

  @override
  void initState() {
    super.initState();
    mountedTree = fetchAndMountTree(widget.businessId);
    gTreeChildren = [];
  }

  @override
  void dispose() {
    super.dispose();
    gTreeChildren = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: () {},
                        style: underSearchBarButtonStyle,
                        child: Row(children: [
                          Image.asset("assets/energy_icon.png"),
                          const Text(" Sensor de Energia"),
                        ]),
                      )),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: () {},
                      style: underSearchBarButtonStyle,
                      child: Row(
                        children: [
                          Image.asset("assets/alert_icon.png"),
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
              future: mountedTree,
              builder: (context, snap) {
                if (snap.hasData && snap.data != null) {
                  return SizedBox(
                    height: 3 * (MediaQuery.of(context).size.height) / 4,
                    child: snap.data!,
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

// TODO: Could've been better implemented: Way too many for loops that
// likely did not had to exist;

Future<Widget> fetchAndMountTree(String businesssId) async {
  var rawListOfAssets = await fetchAssets(businesssId);
  var rawListOfLocations = await fetchLocations(businesssId);

  Map<String, int> assetIdToListIndex = {}; //
  Map<String, int> locationIdToListIndex = {}; //

  for (var index = 0; index < rawListOfAssets!.array.length; index++) {
    final asset = rawListOfAssets.array[index];
    assetIdToListIndex.putIfAbsent(asset.id, () => index);
  }

  for (var index = 0; index < rawListOfLocations!.array.length; index++) {
    final location = rawListOfLocations.array[index];
    locationIdToListIndex.putIfAbsent(location.id, () => index);
  }

  for (var asset in rawListOfAssets.array) {
    if (asset.parentId != null) {
      final parent = rawListOfAssets.array[assetIdToListIndex[asset.parentId]!];
      parent.subAssetsIds.add(asset.id);
    }

    if (asset.locationId != null) {
      final location =
          rawListOfLocations.array[locationIdToListIndex[asset.locationId]!];
      location.subAssetsIds.add(asset.id);
    }
  }

  for (var location in rawListOfLocations.array) {
    if (location.parentId != null) {
      final parent =
          rawListOfLocations.array[locationIdToListIndex[location.parentId]!];
      parent.subLocationsIds.add(location.id);
    }
  }

  //auxiliar Sub-Function
  TreeViewNode mountSubTreeOfAssets(Asset asset) {
    if (asset.subAssetsIds.isEmpty) {
      return TreeViewNode(value: asset.name, leadingIcon: asset.getAssetIcon());
    }

    List<TreeViewNode> children = [];

    for (var subassetId in asset.subAssetsIds) {
      children.add(mountSubTreeOfAssets(
          rawListOfAssets.array[assetIdToListIndex[subassetId]!]));
    }
    return TreeViewNode(
        value: asset.name,
        children: children,
        leadingIcon: asset.getAssetIcon());
  }

  for (var asset in rawListOfAssets.array) {
    if (asset.parentId == null && asset.locationId == null) {
      gTreeChildren.add(mountSubTreeOfAssets(asset));
    }
  }

  //auxiliar Sub-Function
  TreeViewNode mountSubTreeFromLocation(Location location) {
    if (location.subLocationsIds.isEmpty && location.subAssetsIds.isEmpty) {
      return TreeViewNode(
          value: location.name,
          leadingIcon: Image.asset("assets/location_icon.png"));
    }

    List<TreeViewNode> children = [];

    for (var subLocationId in location.subLocationsIds) {
      children.add(mountSubTreeFromLocation(
          rawListOfLocations.array[locationIdToListIndex[subLocationId]!]));
    }

    for (var subAssetId in location.subAssetsIds) {
      print("aquiii;");
      children.add(mountSubTreeOfAssets(
          rawListOfAssets.array[assetIdToListIndex[subAssetId]!]));
    }

    return TreeViewNode(
        value: location.name,
        children: children,
        leadingIcon: Image.asset("assets/location_icon.png"));
  }

  for (var location in rawListOfLocations.array) {
    if (location.parentId == null) {
      gTreeChildren.add(mountSubTreeFromLocation(location));
    }
  }

  return TreeView(
      rootNode: TreeViewNode(children: gTreeChildren, isRoot: true));
}
