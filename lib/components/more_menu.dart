import 'package:flutter/material.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/components/popup_menu.dart';
import 'package:ecalculator/components/logout_dialog.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLogoutDialog(context);
      });
    }

    void about() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Приложение создано учеником школы, использующей eSchool.'
                      '\nДанные для входа отправляются приложением напрямую в eSchool. '
                      'Пароль намеренно не отправляется на серверы eCalculator. '
                      'Если включено «Запомнить меня», приложение сохраняет '
                      'повторно используемые данные авторизации в защищённом '
                      'хранилище операционной системы.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(dialogContext)
                            .textTheme
                            .displayLarge
                            ?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Ок',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(dialogContext)
                                  .textTheme
                                  .displayLarge
                                  ?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    }

    return PopupMenu(
      menuList: [
        PopupMenuItem(
          onTap: about,
          child: ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).textTheme.displayLarge?.color,
            ),
            title: Text(
              "О приложении",
              style: TextStyle(
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
            ),
          ),
        ),
        if (widget.canLeave) const PopupMenuDivider(),
        if (widget.canLeave)
          PopupMenuItem(
            onTap: leave,
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).textTheme.displayLarge?.color,
              ),
              title: Text(
                "Выйти",
                style: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
