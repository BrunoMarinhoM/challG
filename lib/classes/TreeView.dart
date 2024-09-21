import 'package:flutter/material.dart';

class TreeViewNode {
  final String value;
  List<TreeViewNode>? children;
  TreeViewNode({this.value = "", this.children});
}

class TreeView extends StatefulWidget {
  final TreeViewNode root;
  const TreeView({super.key, required this.root});

  @override
  State<StatefulWidget> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  Widget buildTree(TreeViewNode root) {
    root.children = root.children ?? [];
    if (root.children!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: ListTile(title: Text(root.value)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: ExpansionTile(
        title: Text(root.value),
        children: root.children!.map(buildTree).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuEntry> subItems = [];

    return buildTree(widget.root);
  }
}
