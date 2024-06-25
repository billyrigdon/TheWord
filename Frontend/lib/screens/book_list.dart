// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import '../providers/settings_provider.dart';
// import 'reader_screen.dart';
//
// class BookListScreen extends StatefulWidget {
//   @override
//   _BookListScreenState createState() => _BookListScreenState();
// }
//
// class _BookListScreenState extends State<BookListScreen> {
//   List books = [];
//   List filteredBooks = [];
//   bool isLoading = true;
//   bool isSearching = false;
//   TextEditingController searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBooks();
//   }
//
//   void _loadSettings() {
//     Provider.of<SettingsProvider>(context, listen: false).loadSettings();
//   }
//
//   void _loadBooks() {
//     final settingsProvider =
//     Provider.of<SettingsProvider>(context, listen: false);
//     // settingsProvider.addListener(_refreshBooks);
//     _fetchBooks(settingsProvider.currentTranslationId!);
//   }
//
//   @override
//   void dispose() {
//     final settingsProvider =
//     Provider.of<SettingsProvider>(context, listen: false);
//     // settingsProvider.removeListener(_refreshBooks);
//     searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchBooks(String translationId) async {
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//       });
//     }
//
//     final response = await http.get(
//       Uri.parse(
//           'https://api.scripture.api.bible/v1/bibles/$translationId/books'),
//       headers: {'api-key': dotenv.env['BIBLE_KEY'] ?? ''},
//     );
//
//     try {
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (mounted) {
//           setState(() {
//             books = data['data'];
//             filteredBooks = books;
//             isLoading = false;
//           });
//         }
//       } else {
//         throw Exception('Failed to load books');
//       }
//     } catch (err) {
//       throw Exception('Failed to load books');
//     }
//   }
//
//   void _filterBooks(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredBooks = books;
//       } else {
//         filteredBooks = books.where((book) {
//           return book['name'].toLowerCase().contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     Color cardColor = isDarkMode ? Colors.black : Colors.white;
//     final settingsProvider = Provider.of<SettingsProvider>(context);
//     Color lineColor = settingsProvider.currentColor ?? Colors.black;
//
//     return Scaffold(
//       body: Column(
//         children: [
//           SizedBox(
//             height: 80,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Search books...',
//                         border: InputBorder.none,
//                         enabledBorder: UnderlineInputBorder(
//                           borderSide: BorderSide(color: lineColor),
//                         ),
//                         focusedBorder: UnderlineInputBorder(
//                           borderSide: BorderSide(color: lineColor),
//                         ),
//                       ),
//                       onChanged: _filterBooks,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.search, color: lineColor),
//                     onPressed: () {
//                       // Toggle search or clear input based on requirements.
//                       if (searchController.text.isNotEmpty) {
//                         _filterBooks(searchController.text);
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               itemCount: filteredBooks.length,
//               itemBuilder: (context, index) {
//                 String bookId = filteredBooks[index]['id'];
//                 return Card(
//                   color: cardColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius:
//                     BorderRadius.circular(0), // No rounded corners
//                   ),
//                   elevation: 2,
//                   margin: EdgeInsets.zero, // No margin
//                   child: ExpansionTile(
//                     tilePadding: const EdgeInsets.symmetric(
//                         horizontal: 16.0, vertical: 8.0),
//                     title: Text(
//                       filteredBooks[index]['name'],
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18.0,
//                         color:
//                         isDarkMode ? Colors.white : Colors.black,
//                       ),
//                     ),
//                     onExpansionChanged: (bool expanded) {
//                       if (expanded &&
//                           !chapterFutures.containsKey(bookId)) {
//                         if (mounted) {
//                           setState(() {
//                             chapterFutures[bookId] =
//                                 _fetchChapters(bookId);
//                           });
//                         }
//                       }
//                       if (mounted) {
//                         setState(() {
//                           expandedStates[bookId] = expanded;
//                         });
//                       }
//                     },
//                     children: expandedStates[bookId] == true
//                         ? <Widget>[
//                       FutureBuilder<List>(
//                         future: chapterFutures[bookId],
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return const Padding(
//                               padding: EdgeInsets.all(16.0),
//                               child: CircularProgressIndicator(),
//                             );
//                           } else if (snapshot.hasError) {
//                             return const Padding(
//                               padding: EdgeInsets.all(16.0),
//                               child:
//                               Text('Failed to load chapters'),
//                             );
//                           } else {
//                             final chapters = snapshot.data!;
//                             return Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: GridView.builder(
//                                 shrinkWrap: true,
//                                 physics:
//                                 const NeverScrollableScrollPhysics(),
//                                 gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount:
//                                   4, // Adjust the number of columns as needed
//                                   crossAxisSpacing: 10,
//                                   mainAxisSpacing: 10,
//                                   childAspectRatio: 2,
//                                 ),
//                                 itemCount: chapters.length,
//                                 itemBuilder:
//                                     (context, chapterIndex) {
//                                   final chapter =
//                                   chapters[chapterIndex];
//                                   return GestureDetector(
//                                     onTap: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               ReaderScreen(
//                                                 chapterId:
//                                                 chapter['id'],
//                                                 chapterName:
//                                                 'Chapter ${chapter['number']}',
//                                                 chapterIds: chapters
//                                                     .map((c) =>
//                                                 c['id'])
//                                                     .toList(),
//                                                 chapterNames: chapters
//                                                     .map((c) =>
//                                                 'Chapter ${c['number']}')
//                                                     .toList(),
//                                               ),
//                                         ),
//                                       );
//                                     },
//                                     child: Container(
//                                       alignment:
//                                       Alignment.center,
//                                       decoration: BoxDecoration(
//                                         color: isDarkMode
//                                             ? const Color(
//                                             0xFF111111)
//                                             : const Color(
//                                             0xFFF2F2F2),
//                                         borderRadius:
//                                         BorderRadius.circular(
//                                             10),
//                                       ),
//                                       child: Text(
//                                         chapter['number']
//                                             .toString(),
//                                         style: TextStyle(
//                                           color: isDarkMode
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight:
//                                           FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ]
//                         : <Widget>[],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Map<String, Future<List>> chapterFutures = {};
//   Map<String, bool> expandedStates = {};
//
//   Future<List> _fetchChapters(String bookId) async {
//     var settingsProvider =
//     Provider.of<SettingsProvider>(context, listen: false);
//     String translationId = settingsProvider.currentTranslationId!;
//     final response = await http.get(
//       Uri.parse(
//           'https://api.scripture.api.bible/v1/bibles/$translationId/books/$bookId/chapters'),
//       headers: {'api-key': dotenv.env['BIBLE_KEY'] ?? ''},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       List chapters = data['data'];
//       // Exclude the intro chapter
//       return chapters
//           .where((chapter) => chapter['number'] != 'intro')
//           .toList();
//     } else {
//       throw Exception('Failed to load chapters');
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import 'reader_screen.dart';

class BookListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDarkMode ? Colors.black : Colors.white;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bibleProvider = Provider.of<BibleProvider>(context);
    Color lineColor = settingsProvider.currentColor ?? Colors.black;

    // Trigger book loading when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bibleProvider.books.isEmpty && !bibleProvider.isLoadingBooks) {
        bibleProvider.fetchBooks(settingsProvider.currentTranslationId!);
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: bibleProvider.isLoadingBooks
                ? const Center(child: CircularProgressIndicator())
                : bibleProvider.filteredBooks.isEmpty
                ? const Center(child: Text('No books available'))
                : ListView.builder(
              itemCount: bibleProvider.filteredBooks.length,
              itemBuilder: (context, index) {
                String bookId = bibleProvider.filteredBooks[index]['id'];
                String bookName = bibleProvider.filteredBooks[index]['name'];
                return Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    title: Text(
                      bookName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    onExpansionChanged: (bool expanded) {
                      if (expanded && bibleProvider.getChapters(bookId) == null) {
                        bibleProvider.fetchChapters(
                          settingsProvider.currentTranslationId!,
                          bookId,
                        );
                      }
                    },
                    children: bibleProvider.getChapters(bookId) == null
                        ? [const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )]
                        : [
                      Padding(
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
                          itemCount: bibleProvider.getChapters(bookId)!.length,
                          itemBuilder: (context, chapterIndex) {
                            final chapter = bibleProvider.getChapters(bookId)![chapterIndex];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReaderScreen(
                                      bookName: bookName,
                                      chapterId: chapter['id'],
                                      chapterName: 'Chapter ${chapter['number']}',
                                      chapterIds: bibleProvider.getChapters(bookId)!.map((c) => c['id']).toList(),
                                      chapterNames: bibleProvider.getChapters(bookId)!.map((c) => 'Chapter ${c['number']}').toList(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF111111) : const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  chapter['number'].toString(),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
