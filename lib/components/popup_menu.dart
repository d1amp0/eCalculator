import 'package:flutter/material.dart';

class PopupMenu extends StatelessWidget {
  final List<PopupMenuEntry> menuList;

  const PopupMenu({super.key, required this.menuList});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: ((context) => menuList),
      color: Theme.of(context).colorScheme.secondary,
      tooltip: "Открыть меню",
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).textTheme.displaySmall?.color,
        size: 30,
      ),
    );
  }
}
