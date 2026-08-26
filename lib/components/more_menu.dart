import 'package:flutter/material.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/components/popup_menu.dart';

class MoreMenu extends StatefulWidget {
  final bool canLeave;
  final PopoverButton? popoverButton;

  const MoreMenu({super.key, required this.canLeave, this.popoverButton});

  @override
  State<MoreMenu> createState() => _MoreMenuState();
}

class _MoreMenuState extends State<MoreMenu> {
  @override
  Widget build(BuildContext context) {
    void leave() {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              content: SizedBox(
                height: 90,
                child: Column(
                  children: [
                    Text(
                      'Вы уверены, что хотите выйти из аккаунта?',
                      style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: Text('Выйти',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.color)),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Отмена',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color))),
                      ],
                    )
                  ],
                ),
              ),
            );
          });
    }

    void about() {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              content: SizedBox(
                height: 200,
                child: Column(
                  children: [
                    Text(
                      'Приложение создано учеником школы, которая пользуется eschool.'
                      '\nПароль и логин пользователя отправляется на сервер '
                      'app.eschool.center, после чего удаляется для максимальной безопасности.',
                      style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text('Ок',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color))),
                      ],
                    )
                  ],
                ),
              ),
            );
          });
    }

    return PopupMenu(
      menuList: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.info_outline,
                color: Theme.of(context).textTheme.displayLarge?.color),
            title: Text(
              "О приложении",
              style: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color),
            ),
            onTap: () => about(),
          ),
        ),
        if (widget.canLeave) const PopupMenuDivider(),
        if (widget.canLeave)
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).textTheme.displayLarge?.color),
              title: Text(
                "Выйти",
                style: TextStyle(
                    color: Theme.of(context).textTheme.displayLarge?.color),
              ),
              onTap: () => leave(),
            ),
          ),
      ],
    );
  }
}
