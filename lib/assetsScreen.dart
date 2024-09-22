import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals/globals.dart';
import 'classes/TreeView.dart';
import 'classes/Assets.dart';

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
                          const Text(" Sensor de Energia"),
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

Future<Widget> fetchAndMountTree(String businesssId) async {
  var rawList = await fetchAssets(businesssId);

  Map<String, int> auxiliarTreeMap = {}; //
  List<TreeViewNode> treeChildren = [];

  // first populate the map
  for (var index = 0; index < rawList!.array.length; index++) {
    final asset = rawList.array[index];
    auxiliarTreeMap.putIfAbsent(asset.id, () => index);
  }
  //propertly set the parent-child relation
  for (var index = 0; index < rawList.array.length; index++) {
    final asset = rawList.array[index];
    if (asset.parentId != null) {
      final parent = rawList.array[auxiliarTreeMap[asset.parentId]!];
      parent.subAssetsIds.add(asset.id);
    }
  }

  TreeViewNode mountSubTree(Asset asset) {
    if (asset.subAssetsIds.isEmpty) {
      return TreeViewNode(value: asset.name);
    }

    List<TreeViewNode> children = [];

    for (var subassetId in asset.subAssetsIds) {
      children.add(mountSubTree(rawList.array[auxiliarTreeMap[subassetId]!]));
    }
    return TreeViewNode(value: asset.name, children: children);
  }

  for (var asset in rawList.array) {
    if (asset.parentId == null) {
      gTreeChildren.add(mountSubTree(asset));
    }
  }

  return TreeView(
      rootNode: TreeViewNode(children: gTreeChildren, isRoot: true));
}
