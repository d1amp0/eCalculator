import 'package:ecalculator/pages/login_page.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:flutter/material.dart';

Future<void> showLogoutDialog(
  BuildContext context, {
  Future<void> Function()? logout,
}) {
  final logoutAction = logout ?? appSession.exit;
  var isLoggingOut = false;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogBuildContext, setDialogState) => AlertDialog(
        backgroundColor: Theme.of(dialogBuildContext).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
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
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginPage(
                            skipSessionRestore: true,
                          ),
                        ),
                        (route) => false,
                      );
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogBuildContext).colorScheme.error,
            ),
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
