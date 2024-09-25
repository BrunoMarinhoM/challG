import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals/globals.dart';
import 'classes/TreeView.dart';
import 'classes/Assets.dart';
import 'classes/Locations.dart';

List<TreeViewNode> gTreeChildren = [];
List<String> searchList = [];
late Future<bool> isTreeMounted;
late ListOfAssets? rawListOfAssets;
late LocationsList? rawListOfLocations;
late bool onlyEnergySensors;
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
    gTreeChildren = [];
    onlyEnergySensors = false;
    onlyCriticalSensors = false;
    searchList = [];
  }

  @override
  void dispose() {
    super.dispose();
  }

  //TODO: Open all nodes in search:
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

  List<TreeViewNode> getMatchNodesOnMainTree(String query) {
    List<TreeViewNode> queryResult = [];
    for (var childNode in gTreeChildren) {
      if (isNodeNameOnSubTree(query, childNode)) {
        queryResult.add(childNode);
      }
    }
    return queryResult;
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
                        await fetchIfNullAndMountTree(widget.businessId);
                        setState(() {});
                        return;
                      }

                      final queryResults = getMatchesOnListOfNames(query);

                      if (queryResults.isEmpty) {
                        gTreeChildren = [
                          TreeViewNode(
                              isRoot: false,
                              value: "Nem um resultado encontrado")
                        ];
                        setState(() {});
                        return;
                      }

                      gTreeChildren = getMatchNodesOnMainTree(queryResults[0]);
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
                        onPressed: () {},
                        style: underSearchBarButtonStyle,
                        child: Row(children: [
                          Image.asset("assets/energy_icon.png"),
                          const Text(" Sensor de Energia"),
                        ]),
                      )),
                  const SizedBox(width: 10),
                  OutlinedButton(
                      onPressed: () async {
                        onlyCriticalSensors = !onlyCriticalSensors;
                        gTreeChildren = [];
                        setState(() {});
                        await fetchIfNullAndMountTree(widget.businessId);
                        setState(() {});
                        return;
                      },
                      style: underSearchBarButtonStyle,
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/alert_icon.png",
                            color: onlyCriticalSensors
                                ? const Color(0xaaaa0000)
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

// TODO: Could've been better implemented: Way too many for loops that
// likely did not had to exist;
Future<bool> fetchIfNullAndMountTree(String businesssId) async {
  rawListOfAssets = rawListOfAssets ?? await fetchAssets(businesssId);
  rawListOfLocations = rawListOfLocations ?? await fetchLocations(businesssId);

  Map<String, int> assetIdToListIndex = {}; //
  Map<String, int> locationIdToListIndex = {}; //

  for (var index = 0; index < rawListOfAssets!.array.length; index++) {
    final asset = rawListOfAssets!.array[index];
    searchList.add(asset.name);
    assetIdToListIndex.putIfAbsent(asset.id, () => index);
  }

  for (var index = 0; index < rawListOfLocations!.array.length; index++) {
    final location = rawListOfLocations!.array[index];
    searchList.add(location.name);
    locationIdToListIndex.putIfAbsent(location.id, () => index);
  }

  for (var asset in rawListOfAssets!.array) {
    if (asset.parentId != null) {
      final parent =
          rawListOfAssets!.array[assetIdToListIndex[asset.parentId]!];
      parent.subAssetsIds.add(asset.id);
    }

    if (asset.locationId != null) {
      final location =
          rawListOfLocations!.array[locationIdToListIndex[asset.locationId]!];
      location.subAssetsIds.add(asset.id);
    }
  }

  for (var location in rawListOfLocations!.array) {
    if (location.parentId != null) {
      final parent =
          rawListOfLocations!.array[locationIdToListIndex[location.parentId]!];
      parent.subLocationsIds.add(location.id);
    }
  }

  //auxiliar Sub-Function
  TreeViewNode? mountSubTreeOfAssets(Asset asset) {
    if (asset.subAssetsIds.isEmpty &&
        onlyCriticalSensors &&
        asset.getAssetStatus() != AssetStatus.alert) {
      return null;
    }

    if (asset.subAssetsIds.isEmpty) {
      return TreeViewNode(value: asset.name, leadingIcon: asset.getAssetIcon());
    }

    List<TreeViewNode> children = [];

    for (var subassetId in asset.subAssetsIds) {
      var subTree = mountSubTreeOfAssets(
          rawListOfAssets!.array[assetIdToListIndex[subassetId]!]);
      if (subTree == null) {
        continue;
      }
      children.add(subTree);
    }

    return TreeViewNode(
        value: asset.name,
        children: children,
        leadingIcon: asset.getAssetIcon());
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
          rawListOfLocations!.array[locationIdToListIndex[subLocationId]!]));
    }

    for (var subAssetId in location.subAssetsIds) {
      var subTree = mountSubTreeOfAssets(
          rawListOfAssets!.array[assetIdToListIndex[subAssetId]!]);
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

  for (var location in rawListOfLocations!.array) {
    if (location.parentId == null) {
      gTreeChildren.add(mountSubTreeFromLocation(location));
    }
  }

  //Prevent from losing a couple of frames before tree rendering
  gTreeChildren = await Isolate.run(gTreeChildren.reversed.toList);

  for (var asset in rawListOfAssets!.array) {
    if (asset.parentId == null && asset.locationId == null) {
      var subTree = mountSubTreeOfAssets(asset);
      if (subTree == null) {
        continue;
      }
      gTreeChildren.add(subTree);
    }
  }

  return true;
}
