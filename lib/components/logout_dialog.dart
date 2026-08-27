import 'package:ecalculator/navigation/app_routes.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:flutter/material.dart';

Future<void> showLogoutDialog(
  BuildContext context, {
  Future<void> Function()? logout,
}) {
  final logoutAction = logout ?? eschoolSession.logout;
  var isLoggingOut = false;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogBuildContext, setDialogState) => AlertDialog(
        backgroundColor: Theme.of(dialogBuildContext).colorScheme.secondary,
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Сохранённые данные входа eSchool будут удалены. '
          'Настройки приложения останутся без изменений.',
        ),
        actions: [
          TextButton(
            onPressed:
                isLoggingOut ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: isLoggingOut
                ? null
                : () async {
                    setDialogState(() => isLoggingOut = true);
                    try {
                      await logoutAction();
                      if (!dialogContext.mounted || !context.mounted) return;
                      Navigator.of(dialogContext).pop();
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(loginRoute, (route) => false);
                    } on Object {
                      if (!dialogContext.mounted || !context.mounted) return;
                      setDialogState(() => isLoggingOut = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Не удалось очистить безопасное хранилище. '
                            'Повторите выход.',
                          ),
                        ),
                      );
                    }
                  },
            child: isLoggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Выйти'),
          ),
        ],
      ),
    ),
  );
}
