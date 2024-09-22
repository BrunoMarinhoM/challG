import 'package:flutter/material.dart';

class TreeViewNode {
  final String value;
  List<TreeViewNode>? children;
  final bool isRoot; //won't be rendered
  final Color backgroundColor;
  final Widget? leadingIcon;
  bool isExpanded;

  TreeViewNode({
    this.value = "",
    this.children,
    this.leadingIcon,
    this.isRoot = false,
    this.backgroundColor = const Color(0xffffffff),
    this.isExpanded = false,
  });
}

class TreeView extends StatefulWidget {
  final TreeViewNode rootNode;
  const TreeView({super.key, required this.rootNode});

  @override
  State<StatefulWidget> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  @override
  Widget build(BuildContext context) {
    return buildTree(widget.rootNode);
  }
}

Widget getNodeArrowWidget(TreeViewNode node) {
  return node.isExpanded
      ? const Icon(Icons.arrow_drop_down)
      : const Icon(Icons.arrow_drop_up);
}

Widget buildTree(TreeViewNode rootNode) {
  if (!rootNode.isRoot) {
    return const SizedBox();
  }
  return ListView.builder(
    shrinkWrap: true,
    itemCount: rootNode.children!.length,
    itemBuilder: (context, index) {
      return _buildTree(rootNode.children![index]);
    },
  );
}

Widget _buildTree(TreeViewNode node) {
  node.children = node.children ?? [];

  if (node.children!.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(left: 55.0),
      child: ListTile(
        title: Text(node.value),
      ),
    );
  }

  return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(node.value),
        initiallyExpanded: false,
        iconColor: const Color(0xaa9999aa),
        trailing: const SizedBox(),
        leading: getNodeArrowWidget(node),
        collapsedIconColor: const Color(0xaa9999aa),
        backgroundColor: node.backgroundColor,
        children: node.children!.map(_buildTree).toList(),
        onExpansionChanged: (value) {
          node.isExpanded = value;
        },
      ));
}
