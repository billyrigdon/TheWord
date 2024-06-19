// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// //
// // import '../shared/widgets/verse_card.dart';
// // import 'comment_screen.dart';
// //
// // class PublicVersesScreen extends StatefulWidget {
// //   @override
// //   _PublicVersesScreenState createState() => _PublicVersesScreenState();
// // }
// //
// // class _PublicVersesScreenState extends State<PublicVersesScreen> {
// //   List verses = [];
// //   int currentPage = 1;
// //   final int pageSize = 10;
// //   bool isLoading = false;
// //   Map<int, int> likesCount = {};
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchVerses(reset: true);
// //   }
// //
// //   @override
// //   void didChangeDependencies() {
// //     super.didChangeDependencies();
// //     fetchVerses(reset: true);
// //   }
// //
// //   Future<void> fetchVerses({bool reset = false}) async {
// //     if (isLoading) return;
// //
// //     setState(() {
// //       isLoading = true;
// //     });
// //
// //     if (reset) {
// //       verses = [];
// //       currentPage = 1;
// //     }
// //
// //     final response = await http.get(Uri.parse(
// //         'http://10.0.2.2:8080/verses/public?page=$currentPage&pageSize=$pageSize'));
// //     if (response.statusCode == 200) {
// //       List newVerses = json.decode(response.body);
// //       setState(() {
// //         verses.addAll(newVerses);
// //         for (var verse in newVerses) {
// //           int userVerseId = verse['UserVerseID'];
// //           getLikesCount(userVerseId).then((count) {
// //             setState(() {
// //               likesCount[userVerseId] = count;
// //             });
// //           });
// //         }
// //         currentPage++;
// //         isLoading = false;
// //       });
// //     } else {
// //       setState(() {
// //         isLoading = false;
// //       });
// //       throw Exception('Failed to load verses');
// //     }
// //   }
// //
// //   Future<int> getLikesCount(int userVerseId) async {
// //     final response = await http.get(
// //         Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/likes'));
// //     if (response.statusCode == 200) {
// //       return json.decode(response.body)['likes_count'];
// //     } else {
// //       throw Exception('Failed to get likes count');
// //     }
// //   }
// //
// //   Future<void> toggleLike(int userVerseId) async {
// //     final response = await http.post(
// //       Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/toggle-like'),
// //     );
// //     if (response.statusCode == 200) {
// //       int newLikesCount = await getLikesCount(userVerseId);
// //       setState(() {
// //         likesCount[userVerseId] = newLikesCount;
// //       });
// //     } else {
// //       throw Exception('Failed to toggle like');
// //     }
// //   }
// //
// //   void navigateToComments(verse) {
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
// //     );
// //   }
// //
// //   Future<void> _onRefresh() async {
// //     await fetchVerses(reset: true);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: RefreshIndicator(
// //         onRefresh: _onRefresh,
// //         child: verses.isEmpty
// //             ? Center(child: Text('No verses found'))
// //             : NotificationListener<ScrollNotification>(
// //           onNotification: (ScrollNotification scrollInfo) {
// //             if (!isLoading &&
// //                 scrollInfo.metrics.pixels ==
// //                     scrollInfo.metrics.maxScrollExtent) {
// //               fetchVerses();
// //             }
// //             return true;
// //           },
// //           child: ListView.builder(
// //             itemCount: verses.length,
// //             itemBuilder: (context, index) {
// //               final verse = verses[index];
// //               int userVerseId = verse['UserVerseID'];
// //               return VerseCard(
// //                 verseId: verse['VerseID'],
// //                 note: verse['OwnerNote'] ?? 'No notes available',
// //                 likesCount: likesCount[userVerseId] ?? 0,
// //                 onLike: () => toggleLike(userVerseId),
// //                 onComment: () => navigateToComments(verse),
// //                 isSaved: false,
// //                 onSaveNote: (note) {}, // No notes for public verses
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../shared/widgets/verse_card.dart';
// import 'comment_screen.dart';
//
// class PublicVersesScreen extends StatefulWidget {
//   @override
//   _PublicVersesScreenState createState() => _PublicVersesScreenState();
// }
//
// class _PublicVersesScreenState extends State<PublicVersesScreen> {
//   List verses = [];
//   int currentPage = 1;
//   final int pageSize = 10;
//   bool isLoading = false;
//   Map<int, int> likesCount = {};
//   Map<int, int> commentCount = {};
//
//   @override
//   void initState() {
//     super.initState();
//     fetchVerses(reset: true);
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     fetchVerses(reset: true);
//   }
//
//   Future<void> fetchVerses({bool reset = false}) async {
//     if (isLoading) return;
//
//     setState(() {
//       isLoading = true;
//     });
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var token = prefs.getString('token');
//
//     if (reset) {
//       verses = [];
//       currentPage = 1;
//     }
//
//     final response = await http.get(
//       Uri.parse('http://10.0.2.2:8080/verses/public?page=$currentPage&pageSize=$pageSize'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//
//
//     if (response.statusCode == 200) {
//       List newVerses = json.decode(response.body);
//       setState(() {
//         verses.addAll(newVerses);
//         for (var verse in newVerses) {
//           int userVerseId = verse['UserVerseID'];
//           getLikesCount(userVerseId).then((count) {
//             setState(() {
//               likesCount[userVerseId] = count;
//             });
//           });
//           getCommentCount(userVerseId).then((count) {
//             setState(() {
//               commentCount[userVerseId] = count;
//             });
//           });
//         }
//         currentPage++;
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//       throw Exception('Failed to load verses');
//     }
//   }
//
//   Future<int> getLikesCount(int userVerseId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var token = prefs.getString('token');
//
//     final response = await http.get(
//       Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/likes'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body)['likes_count'];
//     } else {
//       throw Exception('Failed to get likes count');
//     }
//   }
//
//   Future<int> getCommentCount(int userVerseId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var token = prefs.getString('token');
//
//     final response = await http.get(
//       Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/comments/count'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body)['comment_count'];
//     } else {
//       throw Exception('Failed to get comment count');
//     }
//   }
//
//   Future<void> toggleLike(int userVerseId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var token = prefs.getString('token');
//
//     final response = await http.post(
//       Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/toggle-like'),
//       headers: {'Authorization': 'Bearer $token'},
//     );
//
//     if (response.statusCode == 200) {
//       int newLikesCount = await getLikesCount(userVerseId);
//       setState(() {
//         likesCount[userVerseId] = newLikesCount;
//       });
//     } else {
//       throw Exception('Failed to toggle like');
//     }
//   }
//
//   void navigateToComments(verse) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
//     );
//   }
//
//   Future<void> _onRefresh() async {
//     await fetchVerses(reset: true);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: RefreshIndicator(
//         onRefresh: _onRefresh,
//         child: verses.isEmpty
//             ? Center(child: Text('No verses found'))
//             : NotificationListener<ScrollNotification>(
//           onNotification: (ScrollNotification scrollInfo) {
//             if (!isLoading &&
//                 scrollInfo.metrics.pixels ==
//                     scrollInfo.metrics.maxScrollExtent) {
//               fetchVerses();
//             }
//             return true;
//           },
//           child: ListView.builder(
//             itemCount: verses.length,
//             itemBuilder: (context, index) {
//               final verse = verses[index];
//               int userVerseId = verse['UserVerseID'];
//               return VerseCard(
//                 verseId: verse['VerseID'],
//                 note: verse['Note'] ?? 'No notes available',
//                 likesCount: likesCount[userVerseId] ?? 0,
//                 commentCount: commentCount[userVerseId] ?? 0,
//                 onLike: () => toggleLike(userVerseId),
//                 onComment: () => navigateToComments(verse),
//                 isSaved: false,
//                 onSaveNote: (note) {}, // No notes for public verses
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
// public_verses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/verse_provider.dart';
import '../shared/widgets/verse_card.dart';
import 'comment_screen.dart';

class PublicVersesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final verseProvider = Provider.of<VerseProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await verseProvider.fetchPublicVerses(reset: true);
        },
        child: verseProvider.publicVerses.isEmpty
            ? const Center(child: Text('No public verses'))
            : ListView.builder(
            itemCount: verseProvider.publicVerses.length,
            itemBuilder: (context, index) {
              final verse = verseProvider.publicVerses[index];
              int userVerseId = verse['UserVerseID'];

              return VerseCard(
                verseId: verse['VerseID'],
                isPublished: true,
                verseContent: verse['Content'],
                username: verse['username'],
                note: verse['Note'] ?? 'No notes available',
                likesCount: verseProvider.likesCount[userVerseId] ?? 0,
                commentCount:
                verseProvider.commentCount[userVerseId] ?? 0,
                onLike: () => verseProvider.toggleLike(userVerseId),
                onComment: () => _navigateToComments(context, verse),
                isSaved: false,
                onSaveNote: (note) {},
              );
            },
          ),

      ),
    );
  }

  void _navigateToComments(BuildContext context, verse) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
    );
  }
}
