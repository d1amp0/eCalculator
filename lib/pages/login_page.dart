import 'package:ecalculator/components/error_message.dart';
import 'package:ecalculator/components/icon_button.dart';
import 'package:ecalculator/components/input.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/pages/main_page.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:flutter/material.dart';
import 'package:ecalculator/other/colors.dart' as colors;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();

  bool rememberMe = false,
      isEnabled = false,
      isLoading = false,
      isRestoringSession = true;

  void remember(bool? value) {
    setState(() {
      rememberMe = !rememberMe;
    });
  }

  void checkFields() {
    setState(() {
      isEnabled = usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  Future<void> restoreSession() async {
    final restored = await eschoolSession.restore();
    if (!mounted) return;
    if (restored) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
      return;
    }
    setState(() => isRestoringSession = false);
  }

  Future<void> login() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      if (usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        String username = usernameController.text;
        String password = passwordController.text;
        final result = await loginTry(
          username,
          password,
          rememberMe: rememberMe,
        );
        if (!mounted) return;
        switch (result) {
          case LoginResult.authenticated:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
            return;
          case LoginResult.authenticatedWithoutPersistence:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Безопасное хранилище недоступно. Вход действует только до закрытия приложения.',
                ),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
            return;
          case LoginResult.invalidCredentials:
            showErrorLogin(context);
            return;
          case LoginResult.forbidden:
            showErrorLogin(
              context,
              message: 'eSchool временно отклонил запрос. Попробуйте позже.',
            );
            return;
          case LoginResult.rateLimited:
            showErrorLogin(
              context,
              message: 'Слишком много запросов к eSchool. Попробуйте позже.',
            );
            return;
          case LoginResult.unavailable:
            showErrorLogin(
              context,
              message: 'Не удалось подключиться к eSchool. '
                  'Проверьте интернет или попробуйте позже.',
            );
            return;
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isRestoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Row(children: [Spacer(), MoreMenu(canLeave: false)]),
            const Spacer(),
            Center(
              child: Container(
                height: 350,
                width: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  shape: BoxShape.rectangle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: Column(
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset(
                          Theme.of(context).textTheme.displayLarge?.color !=
                                  Colors.white
                              ? 'lib/images/icon_new.png'
                              : 'lib/images/icon_black.png',
                          height: 96,
                          width: 96,
                          cacheWidth: 192,
                        ),
                        Text(
                          'eCalculator',
                          style: TextStyle(
                            fontSize: 28,
                            color: colors.defaultPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    MyInput(
                      controller: usernameController,
                      hint: 'Логин',
                      onChanged: (_) => checkFields(),
                    ),
                    const SizedBox(height: 20),
                    MyInput(
                      controller: passwordController,
                      hint: 'Пароль',
                      onChanged: (_) => checkFields(),
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Row(
                        children: [
                          Checkbox(
                            activeColor: Theme.of(context).colorScheme.primary,
                            side: const BorderSide(color: Colors.grey),
                            value: rememberMe,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            onChanged: (value) => remember(value),
                          ),
                          const Text(
                            'Запомнить меня',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: login,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 25.0),
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context)
                                              .textTheme
                                              .displaySmall
                                              ?.color ??
                                          Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Войти',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.color,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Связаться с разработчиком',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.displaySmall?.color,
              ),
            ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyIconButton(path: 'lib/images/telegram_icon.png', type: 0),
                SizedBox(width: 100),
                MyIconButton(path: 'lib/images/mail_icon.png', type: 1),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
