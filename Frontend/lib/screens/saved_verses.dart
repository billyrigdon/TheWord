// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../shared/widgets/verse_card.dart';
//
// class SavedVersesScreen extends StatefulWidget {
//   @override
//   _SavedVersesScreenState createState() => _SavedVersesScreenState();
// }
//
// class _SavedVersesScreenState extends State<SavedVersesScreen> {
//   List<MapEntry<String, dynamic>> _sortedVerses = [];
//
//   @override
//   void initState() {
//     _loadAndSortVerses();
//     super.initState();
//   }
//
//   Future<Map<String, dynamic>> loadSavedVerses() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? versesJson = prefs.getString('verses');
//     if (versesJson != null) {
//       try {
//         return Map<String, dynamic>.from(json.decode(versesJson));
//       } catch (e) {
//         print('Error decoding verses: $e');
//       }
//     }
//     return {};
//   }
//
//   List<MapEntry<String, dynamic>> sortVersesById(Map<String, dynamic> verses) {
//     List<MapEntry<String, dynamic>> entries = verses.entries.toList();
//     entries.sort((a, b) {
//       List<String> aParts = a.key.split('.');
//       List<String> bParts = b.key.split('.');
//
//       int bookComparison = aParts[0].compareTo(bParts[0]);
//       if (bookComparison != 0) return bookComparison;
//
//       int chapterComparison = int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
//       if (chapterComparison != 0) return chapterComparison;
//
//       return int.parse(aParts[2]).compareTo(int.parse(bParts[2]));
//     });
//     return entries;
//   }
//
//   Future<void> _loadAndSortVerses() async {
//     Map<String, dynamic> savedVerses = await loadSavedVerses();
//     List<MapEntry<String, dynamic>> sortedVerses = sortVersesById(savedVerses);
//
//     setState(() {
//       _sortedVerses = sortedVerses;
//     });
//   }
//
//   Future<void> _saveNote(String verseId, String note) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? storedVersesJson = prefs.getString('verses');
//     if (storedVersesJson != null) {
//       Map<String, dynamic> storedVerses = Map<String, dynamic>.from(json.decode(storedVersesJson));
//       if (storedVerses.containsKey(verseId)) {
//         storedVerses[verseId]['note'] = note;
//         await prefs.setString('verses', json.encode(storedVerses));
//         setState(() {
//           _sortedVerses = sortVersesById(storedVerses);
//         });
//       }
//     }
//   }
//
//   Future<void> _removeVerse(String verseId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? storedVersesJson = prefs.getString('verses');
//     if (storedVersesJson != null) {
//       Map<String, dynamic> storedVerses = Map<String, dynamic>.from(json.decode(storedVersesJson));
//       if (storedVerses.containsKey(verseId)) {
//         storedVerses.remove(verseId);
//         await prefs.setString('verses', json.encode(storedVerses));
//         setState(() {
//           _sortedVerses = _sortedVerses.where((verse) => verse.key != verseId).toList();
//           _removeHighlightedVerse(verseId);
//         });
//       }
//     }
//   }
//
//   Future<void> _removeHighlightedVerse(String verseId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     List<String> highlightedVerses = prefs.getStringList('highlightedVerses') ?? [];
//
//     if (highlightedVerses.contains(verseId)) {
//       highlightedVerses.remove(verseId);
//     }
//     await prefs.setStringList('highlightedVerses', highlightedVerses);
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Saved Verses'),
//       ),
//       body: _sortedVerses.isEmpty
//           ? const Text('No saved verses')
//           : ListView.builder(
//         itemCount: _sortedVerses.length,
//         itemBuilder: (context, index) {
//           final verse = _sortedVerses[index];
//           return Dismissible(
//             key: Key(verse.key),
//             direction: DismissDirection.endToStart,
//             background: Container(
//               color: Colors.red,
//               alignment: Alignment.centerRight,
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: const Icon(Icons.delete, color: Colors.white),
//             ),
//             onDismissed: (direction) {
//               _removeVerse(verse.key);
//             },
//             child: VerseCard(
//               verseId: verse.key,
//               verseText: verse.value['text'],
//               note: verse.value['note'] ?? '',
//               onSaveNote: (note) => _saveNote(verse.key, note),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../shared/widgets/verse_card.dart';
import 'comment_screen.dart';

class SavedVersesScreen extends StatefulWidget {
  @override
  _SavedVersesScreenState createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends State<SavedVersesScreen> {
  List<dynamic> _savedVerses = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadAndSortVerses();
  }

  Future<void> _loadAndSortVerses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      final response = await http.get(
        Uri.parse('http://billyrigdon.dev:8110/verses/saved'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> savedVerses = json.decode(response.body);

        // Validate and sort saved verses
        savedVerses.removeWhere((verse) {
          if (verse['VerseID'] == null || !verse['VerseID'].contains('.')) {
            return true; // Remove invalid entries
          }
          return false;
        });

        if (savedVerses.length > 1) {
          savedVerses.sort((a, b) {
            List<String> aParts = a['VerseID'].split('.');
            List<String> bParts = b['VerseID'].split('.');

            int bookComparison = aParts[0].compareTo(bParts[0]);
            if (bookComparison != 0) return bookComparison;

            int chapterComparison = int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
            if (chapterComparison != 0) return chapterComparison;

            return int.parse(aParts[2]).compareTo(int.parse(bParts[2]));
          });
        }

        setState(() {
          _savedVerses = savedVerses;
        });
      } else {
        print('Failed to load saved verses: ${response.body}');
      }
    }
  }

  Future<void> _unsaveVerse(verse) async {
    if (_token == null) return;

    final response = await http.delete(
      Uri.parse('http://billyrigdon.dev:8110/verses/${verse['UserVerseID']}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _savedVerses = _savedVerses.where((savedVerse) => savedVerse['UserVerseID'] != verse['UserVerseID']).toList();
      });
    } else {
      print('Failed to unsave verse: ${response.body}');
    }
  }

  void _navigateToComments(verse) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Verses'),
      ),
      body: _savedVerses.isEmpty
          ? const Center(child: Text('No saved verses'))
          : ListView.builder(
        itemCount: _savedVerses.length,
        itemBuilder: (context, index) {
          final verse = _savedVerses[index];
          return Dismissible(
            key: Key(verse['VerseID']),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _unsaveVerse(verse);
            },
            child: InkWell(
              onTap: () => _navigateToComments(verse),
              child: VerseCard(
                verseId: verse['VerseID'],
                verseText: verse['Content'],
                note: verse['Note'] ?? '',
                onSaveNote: (note) => _saveNote(
                  verse['VerseID'].toString(),
                  verse['UserVerseID'].toString(),
                  note: note,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveNote(String verseId, String userVerseId, {String note = ''}) async {
    if (_token == null) return;

    final existingVerse = _savedVerses.firstWhere(
          (element) => element['VerseID'].toString() == verseId,
      orElse: () => null,
    );

    if (existingVerse == null) {
      print('Verse not found for verseId: $verseId');
      return;
    }

    final verseData = {
      'note': note,
    };

    final response = await http.put(
      Uri.parse('http://billyrigdon.dev:8110/verses/$userVerseId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode(verseData),
    );

    if (response.statusCode == 200) {
      setState(() {
        existingVerse['Note'] = note;
      });
    } else {
      print('Failed to update note: ${response.body}');
    }
  }
}
