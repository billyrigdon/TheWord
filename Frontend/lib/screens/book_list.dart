import 'dart:convert';
import 'package:TheWord/screens/login_screen.dart';
import 'package:TheWord/screens/public_verses.dart';
import 'package:TheWord/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'reader_screen.dart';
import 'saved_verses.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadSettings();
  }

  void _loadSettings() {
    Provider.of<SettingsProvider>(context, listen: false).loadSettings();
  }

  void _loadBooks() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.addListener(_refreshBooks);
    _fetchBooks(settingsProvider.currentTranslationId!);
  }

  @override
  void dispose() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.removeListener(_refreshBooks);
    super.dispose();
  }

  Future<void> _refreshBooks() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await _fetchBooks(settingsProvider.currentTranslationId!);
  }

  Future<void> _fetchBooks(String translationId) async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books'),
      headers: {'api-key': dotenv.env['BIBLE_KEY'] ?? ''},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        books = data['data'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load books');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDarkMode ? Colors.black : Colors.white;
    SettingsProvider settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          // If user not logged in:
          if (!settingsProvider.isLoggedIn)
          IconButton(
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
              icon: const Icon(Icons.app_registration),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PublicVersesScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.sticky_note_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedVersesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
          ),
          IconButton(
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
              icon: const Icon(Icons.logout),
              onPressed: () {
                settingsProvider.logout();
              },
            ),
        ],
        title: const Text('The Word'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          String bookId = books[index]['id'];
          return Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0), // No rounded corners
            ),
            elevation: 2,
            margin: EdgeInsets.zero, // No margin
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Text(
                books[index]['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onExpansionChanged: (bool expanded) {
                if (expanded && !chapterFutures.containsKey(bookId)) {
                  setState(() {
                    chapterFutures[bookId] = _fetchChapters(bookId);
                  });
                }
                setState(() {
                  expandedStates[bookId] = expanded;
                });
              },
              children: expandedStates[bookId] == true
                  ? <Widget>[
                FutureBuilder<List>(
                  future: chapterFutures[bookId],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Failed to load chapters'),
                      );
                    } else {
                      final chapters = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // Adjust the number of columns as needed
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2,
                          ),
                          itemCount: chapters.length,
                          itemBuilder: (context, chapterIndex) {
                            final chapter = chapters[chapterIndex];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReaderScreen(
                                      chapterId: chapter['id'],
                                      chapterName: 'Chapter ${chapter['number']}',
                                      chapterIds: chapters.map((c) => c['id']).toList(),
                                      chapterNames: chapters.map((c) => 'Chapter ${c['number']}').toList(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  chapter['number'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              ]
                  : <Widget>[],
            ),
          );
        },
      ),
    );
  }

  Map<String, Future<List>> chapterFutures = {};
  Map<String, bool> expandedStates = {};

  Future<List> _fetchChapters(String bookId) async {
    var settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    String translationId = settingsProvider.currentTranslationId!;
    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books/$bookId/chapters'),
      headers: {'api-key': dotenv.env['BIBLE_KEY'] ?? ''},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List chapters = data['data'];
      // Exclude the intro chapter
      return chapters.where((chapter) => chapter['number'] != 'intro').toList();
    } else {
      throw Exception('Failed to load chapters');
    }
  }
}

