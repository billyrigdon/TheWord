import 'dart:convert';
import 'package:TheWord/providers/bible_provider.dart';
import 'package:TheWord/providers/friend_provider.dart';
import 'package:TheWord/providers/notification_provider.dart';
import 'package:TheWord/providers/settings_provider.dart';
import 'package:TheWord/providers/verse_provider.dart';
import 'package:TheWord/screens/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/book_list.dart';
import 'screens/settings_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => BibleProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => VerseProvider()),
      ],
      child: TheWordApp(),
    ),
  );
}

class TheWordApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        BibleProvider bibleProvider = Provider.of<BibleProvider>(context, listen: false);
        bibleProvider.fetchTranslations();

        var themeFontColor = settings.currentThemeMode == ThemeMode.dark ? Colors.white : Colors.black;
        if (settings.currentColor != null)  themeFontColor = settings.getFontColor(settings.currentColor!);

        return MaterialApp(

          title: 'The Word',
          themeMode: settings.currentThemeMode,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: settings.currentColor,
            scaffoldBackgroundColor: Colors.black,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
            appBarTheme: AppBarTheme(
              foregroundColor: themeFontColor,
              backgroundColor: settings.currentColor,
              titleTextStyle: TextStyle(color: themeFontColor, fontSize: 20),
            ),
            bottomAppBarTheme: BottomAppBarTheme(
              surfaceTintColor: themeFontColor,
              color: settings.currentColor,
            ),
            listTileTheme: const ListTileThemeData(
              textColor: Colors.white,
              iconColor: Colors.white,
            ),
          ),
          theme: ThemeData(
            highlightColor: settings.highlightColor,
            brightness: Brightness.light,
            primarySwatch: settings.currentColor,
            scaffoldBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
            ),
            appBarTheme: AppBarTheme(
              foregroundColor: themeFontColor,
              backgroundColor: settings.currentColor,
              titleTextStyle: TextStyle(color: themeFontColor, fontSize: 20),
            ),
            bottomAppBarTheme: BottomAppBarTheme(
              surfaceTintColor: themeFontColor,
              color: settings.currentColor,
            ),
            listTileTheme: const ListTileThemeData(
              textColor: Colors.black,
              iconColor: Colors.black,
            ),
          ),
          home: MainAppScreen(),
        );
      },
    );
  }
}

MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};

  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}
