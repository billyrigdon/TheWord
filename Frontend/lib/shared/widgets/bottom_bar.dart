import 'package:TheWord/providers/friend_provider.dart';
import 'package:TheWord/providers/verse_provider.dart';
import 'package:TheWord/screens/chat_screen.dart';
import 'package:TheWord/screens/notification_screen.dart';
import 'package:TheWord/screens/public_verses.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/book_list.dart';
import '../../screens/login_screen.dart';
import '../../screens/registration_screen.dart';
import '../../screens/saved_verses.dart';
import '../../screens/friend_list_screen.dart';
import '../../screens/settings_screen.dart';

class BottomBarNavigation extends StatefulWidget {
  @override
  _BottomBarNavigationState createState() => _BottomBarNavigationState();
}

class _BottomBarNavigationState extends State<BottomBarNavigation> {
  int _currentIndex = 0;
  bool isInited = false;
  late SettingsProvider settingsProvider;
  late FriendProvider friendProvider;
  late VerseProvider verseProvider;
  List<dynamic> friendRequests = [];

  Future<void> init() async {
    await verseProvider.init();
    await friendProvider.fetchFriends();
    await friendProvider.fetchSuggestedFriends();
    await friendProvider.fetchFriendRequests();
    setState(() {
      friendRequests = friendProvider.friendRequests;
      isInited = true;
    });
  }

  @override void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    settingsProvider = Provider.of<SettingsProvider>(context);
    friendProvider = Provider.of<FriendProvider>(context, listen: false);
    verseProvider = Provider.of<VerseProvider>(context, listen: false);

    if (settingsProvider.isLoggedIn && !isInited) {
      this.init();
    }

    // Get current color from settings
    MaterialColor? currentColor = settingsProvider.currentColor;
    Color? fontColor = Colors.white;
    if (currentColor != null) {
      fontColor = settingsProvider.getFontColor(currentColor!);
    }
    // Define the screens associated with each index
    List<Widget> _screens = [
      BookListScreen(),
      PublicVersesScreen(),
      SavedVersesScreen(),
      FriendListScreen(),
      ChatScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('The Word'),
          backgroundColor: currentColor,
          automaticallyImplyLeading: false,
          actions: [
            if (!settingsProvider.isLoggedIn)
              IconButton(
                color: fontColor,
                icon: const Icon(Icons.login),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            if (!settingsProvider.isLoggedIn)
              IconButton(
                color: fontColor,
                icon: const Icon(Icons.app_registration),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationScreen()),
                  );
                },
              ),
            if (settingsProvider.isLoggedIn)
              IconButton(
                color: fontColor,
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (friendRequests.isNotEmpty)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${friendRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    this.friendRequests = [];
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(),
                    ),
                  );
                },
              ),
            IconButton(
              color: fontColor,
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            if (settingsProvider.isLoggedIn)
              IconButton(
                color: fontColor,
                icon: const Icon(Icons.logout),
                onPressed: () {
                  isInited = false;
                  friendProvider.reset();
                  settingsProvider.logout();
                  Provider.of<VerseProvider>(context, listen: false).reset();
                },
              ),
          ],
        ),
        body: settingsProvider.isLoggedIn
            ? IndexedStack(
          index: _currentIndex,
          children: _screens,
        )
            : BookListScreen(), // Display only the BookListScreen if not logged in
        bottomNavigationBar: settingsProvider.isLoggedIn
            ? Theme(
          data: ThemeData(
            canvasColor: currentColor, // Set canvasColor to currentColor
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.book, color: fontColor,),
                label: 'Bible',
              ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore, color: fontColor,),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, color: fontColor,),
                  label: 'My Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group, color: fontColor,),
                  label: 'Friends',
                ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat, color: fontColor,),
                label: 'Ask Archie',
              ),
            ],
            selectedItemColor: _getContrastingTextColor(currentColor ?? createMaterialColor(Colors.black)),
            unselectedItemColor: _getContrastingTextColor(currentColor ?? createMaterialColor(Colors.black)).withOpacity(0.6),
            showUnselectedLabels: true,
          ),
        )
            : null, // No bottom bar if not logged in
      ),
    );
  }

  // Function to get a contrasting text color
  Color _getContrastingTextColor(MaterialColor backgroundColor) {
    // Calculate brightness to determine if white or black text is more readable
    int brightnessValue = ((backgroundColor.red * 299) +
        (backgroundColor.green * 587) +
        (backgroundColor.blue * 114)) ~/ 1000; // Integer division
    return brightnessValue > 128 ? Colors.black : Colors.white;
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
  
}
