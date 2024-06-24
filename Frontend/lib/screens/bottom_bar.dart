import 'dart:async';

import 'package:TheWord/providers/bible_provider.dart';
import 'package:TheWord/providers/friend_provider.dart';
import 'package:TheWord/providers/notification_provider.dart';
import 'package:TheWord/providers/verse_provider.dart';
import 'package:TheWord/screens/chat_screen.dart';
import 'package:TheWord/screens/notification_screen.dart';
import 'package:TheWord/screens/public_verses.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'book_list.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'saved_verses.dart';
import 'friend_list_screen.dart';
import 'settings_screen.dart';
import '../shared/widgets/dynamic_search_bar.dart';

//42 * 5
class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  bool isInited = false;
  late SettingsProvider settingsProvider;
  late FriendProvider friendProvider;
  late VerseProvider verseProvider;

  int notifications = 0;
  Timer? _timer;

  Future<void> init() async {
    await verseProvider.init();
    await friendProvider.fetchFriends();
    await friendProvider.fetchSuggestedFriends();

    NotificationProvider notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.fetchAllNotifications();
    setState(() {
      isInited = true;
      notifications = notificationProvider.friendRequests.length +
          notificationProvider.commentNotifications.length;
    });

    _startPeriodicNotificationFetch();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicNotificationFetch() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 30), (Timer t) async {
      NotificationProvider notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.fetchAllNotifications();
      setState(() {
        notifications = notificationProvider.friendRequests.length +
            notificationProvider.commentNotifications.length;
      });
    });
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
      fontColor = settingsProvider.getFontColor(currentColor);
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: AppBar(
            backgroundColor: currentColor,
            automaticallyImplyLeading: false,
            flexibleSpace: Center(
              child: Container(
                padding: EdgeInsets.only(top: 36, left: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Image.asset(
                          'assets/icon/app_icon.png', // Update with your logo path
                          height: 60,
                          width: 60,
                        ),
                      ),
                      if (_currentIndex == 0)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 14.0),
                            child: SizedBox(
                              height: 36,
                              child: DynamicSearchBar(
                                data: Provider.of<BibleProvider>(context,
                                        listen: false)
                                    .books, // Pass the dynamic data here
                                searchType: SearchType
                                    .BibleBooks, // Choose the appropriate search type
                                fontColor: fontColor,
                              ),
                            ),
                          ),
                        ),
                      // Spacer(), // Add another spacer for even spacing
                      Row( children: [
                      if (!settingsProvider.isLoggedIn)
                        IconButton(
                          color: fontColor,
                          icon: const Icon(Icons.login),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
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
                              MaterialPageRoute(
                                  builder: (context) => RegistrationScreen()),
                            );
                          },
                        ),
                      IconButton(
                        color: fontColor,
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsScreen()),
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
                            _timer?.cancel();
                            Provider.of<VerseProvider>(context, listen: false)
                                .reset();
                          },
                        ),
                      ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                      icon: Icon(
                        Icons.book,
                        color: fontColor,
                      ),
                      label: 'Bible',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.explore,
                        color: fontColor,
                      ),
                      label: 'Explore',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.home,
                        color: fontColor,
                      ),
                      label: 'My Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.group,
                        color: fontColor,
                      ),
                      label: 'Friends',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.chat,
                        color: fontColor,
                      ),
                      label: 'Ask Archie',
                    ),
                  ],
                  selectedItemColor: _getContrastingTextColor(
                      currentColor ?? createMaterialColor(Colors.black)),
                  unselectedItemColor: _getContrastingTextColor(
                          currentColor ?? createMaterialColor(Colors.black))
                      .withOpacity(0.6),
                  showUnselectedLabels: true,
                ),
              )
            : null, // No bottom bar if not logged in
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   settingsProvider = Provider.of<SettingsProvider>(context);
  //   friendProvider = Provider.of<FriendProvider>(context, listen: false);
  //   verseProvider = Provider.of<VerseProvider>(context, listen: false);
  //
  //   if (settingsProvider.isLoggedIn && !isInited) {
  //     this.init();
  //   }
  //
  //   // Get current color from settings
  //   MaterialColor? currentColor = settingsProvider.currentColor;
  //   Color? fontColor = Colors.white;
  //   if (currentColor != null) {
  //     fontColor = settingsProvider.getFontColor(currentColor);
  //   }
  //   // Define the screens associated with each index
  //   List<Widget> _screens = [
  //     BookListScreen(),
  //     PublicVersesScreen(),
  //     SavedVersesScreen(),
  //     FriendListScreen(),
  //     ChatScreen(),
  //   ];
  //
  //   return WillPopScope(
  //     onWillPop: () async {
  //       return false;
  //     },
  //     child: Scaffold(
  //       appBar: AppBar(
  //         title: const Text('The Word'),
  //         backgroundColor: currentColor,
  //         automaticallyImplyLeading: false,
  //         actions: [
  //           if (!settingsProvider.isLoggedIn)
  //             IconButton(
  //               color: fontColor,
  //               icon: const Icon(Icons.login),
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(builder: (context) => LoginScreen()),
  //                 );
  //               },
  //             ),
  //           if (!settingsProvider.isLoggedIn)
  //             IconButton(
  //               color: fontColor,
  //               icon: const Icon(Icons.app_registration),
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) => RegistrationScreen()),
  //                 );
  //               },
  //             ),
  //           if (settingsProvider.isLoggedIn)
  //             IconButton(
  //               color: fontColor,
  //               icon: Stack(
  //                 children: [
  //                   const Icon(Icons.notifications),
  //                   if (notifications > 0)
  //                     Positioned(
  //                       right: 0,
  //                       child: Container(
  //                         padding: const EdgeInsets.all(1),
  //                         decoration: BoxDecoration(
  //                           color: Colors.red,
  //                           borderRadius: BorderRadius.circular(6),
  //                         ),
  //                         constraints: const BoxConstraints(
  //                           minWidth: 12,
  //                           minHeight: 12,
  //                         ),
  //                         child: Text(
  //                           notifications.toString(),
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 8,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //               onPressed: () {
  //                 setState(() {
  //                   notifications = 0;
  //                 });
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => NotificationScreen(),
  //                   ),
  //                 );
  //               },
  //             ),
  //           IconButton(
  //             color: fontColor,
  //             icon: const Icon(Icons.settings),
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => SettingsScreen()),
  //               );
  //             },
  //           ),
  //           if (settingsProvider.isLoggedIn)
  //             IconButton(
  //               color: fontColor,
  //               icon: const Icon(Icons.logout),
  //               onPressed: () {
  //                 isInited = false;
  //                 friendProvider.reset();
  //                 settingsProvider.logout();
  //                 _timer?.cancel();
  //                 Provider.of<VerseProvider>(context, listen: false).reset();
  //               },
  //             ),
  //         ],
  //       ),
  //       body: settingsProvider.isLoggedIn
  //           ? IndexedStack(
  //               index: _currentIndex,
  //               children: _screens,
  //             )
  //           : BookListScreen(), // Display only the BookListScreen if not logged in
  //       bottomNavigationBar: settingsProvider.isLoggedIn
  //           ? Theme(
  //               data: ThemeData(
  //                 canvasColor: currentColor, // Set canvasColor to currentColor
  //               ),
  //               child: BottomNavigationBar(
  //                 type: BottomNavigationBarType.fixed,
  //                 currentIndex: _currentIndex,
  //                 onTap: (index) {
  //                   setState(() {
  //                     _currentIndex = index;
  //                   });
  //                 },
  //                 items: [
  //                   BottomNavigationBarItem(
  //                     icon: Icon(
  //                       Icons.book,
  //                       color: fontColor,
  //                     ),
  //                     label: 'Bible',
  //                   ),
  //                   BottomNavigationBarItem(
  //                     icon: Icon(
  //                       Icons.explore,
  //                       color: fontColor,
  //                     ),
  //                     label: 'Explore',
  //                   ),
  //                   BottomNavigationBarItem(
  //                     icon: Icon(
  //                       Icons.home,
  //                       color: fontColor,
  //                     ),
  //                     label: 'My Home',
  //                   ),
  //                   BottomNavigationBarItem(
  //                     icon: Icon(
  //                       Icons.group,
  //                       color: fontColor,
  //                     ),
  //                     label: 'Friends',
  //                   ),
  //                   BottomNavigationBarItem(
  //                     icon: Icon(
  //                       Icons.chat,
  //                       color: fontColor,
  //                     ),
  //                     label: 'Ask Archie',
  //                   ),
  //                 ],
  //                 selectedItemColor: _getContrastingTextColor(
  //                     currentColor ?? createMaterialColor(Colors.black)),
  //                 unselectedItemColor: _getContrastingTextColor(
  //                         currentColor ?? createMaterialColor(Colors.black))
  //                     .withOpacity(0.6),
  //                 showUnselectedLabels: true,
  //               ),
  //             )
  //           : null, // No bottom bar if not logged in
  //     ),
  //   );
  // }

  // Function to get a contrasting text color
  Color _getContrastingTextColor(MaterialColor backgroundColor) {
    // Calculate brightness to determine if white or black text is more readable
    int brightnessValue = ((backgroundColor.red * 299) +
            (backgroundColor.green * 587) +
            (backgroundColor.blue * 114)) ~/
        1000; // Integer division
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
