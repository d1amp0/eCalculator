import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ecalculator/components/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:ecalculator/navigation/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  databaseFactoryOrNull = null;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final int? index = await SettingsStorage().readInt("theme");

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(index),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {loginRoute: (context) => const LoginPage()},
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
