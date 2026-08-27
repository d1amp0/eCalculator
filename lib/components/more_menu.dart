import 'package:ecalculator/components/logout_dialog.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum _MoreMenuAction { about, logout }

class MoreMenu extends StatelessWidget {
  const MoreMenu({super.key, required this.canLeave});

  final bool canLeave;

  Future<void> _showAbout(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return AlertDialog(
          key: const ValueKey('about-dialog'),
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          icon: Image.asset(
            'lib/images/icon_new.png',
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) => Icon(
              Icons.calculate_rounded,
              size: 48,
              color: scheme.primary,
            ),
          ),
          title: Text(
            'eCalculator',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Неофициальное приложение для оценок и заданий eSchool.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Вход выполняется напрямую в eSchool. Пароль намеренно не '
                  'отправляется на серверы eCalculator; сохранённые данные '
                  'авторизации хранятся в защищённом хранилище ОС.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse('https://t.me/d1amp0'),
                      ),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Telegram'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: 'cuberubex@yandex.ru'),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Почта разработчика скопирована.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Почта'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final menu = PopupMenuButton<_MoreMenuAction>(
      key: const ValueKey('more-menu-button'),
      tooltip: 'Открыть меню',
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      icon: Icon(
        Icons.more_vert,
        color: AppThemeColors.scaffoldText(context),
      ),
      onSelected: (action) {
        switch (action) {
          case _MoreMenuAction.about:
            _showAbout(context);
          case _MoreMenuAction.logout:
            showLogoutDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey('about-menu-item'),
          value: _MoreMenuAction.about,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
            title: Text(
              'О приложении',
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
        ),
        if (canLeave) const PopupMenuDivider(),
        if (canLeave)
          PopupMenuItem(
            key: const ValueKey('logout-menu-item'),
            value: _MoreMenuAction.logout,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Выйти', style: TextStyle(color: scheme.error)),
            ),
          ),
      ],
    );

    if (!appSession.isDemo) return menu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Демонстрационный аккаунт',
          child: const Chip(
            avatar: Icon(Icons.science_outlined, size: 16),
            label: Text('Демо'),
            visualDensity: VisualDensity.compact,
          ),
        ),
        menu,
      ],
    );
  }
}
