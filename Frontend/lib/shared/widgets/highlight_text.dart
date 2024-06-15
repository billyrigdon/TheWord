// import 'dart:convert';
// import 'package:TheWord/models/verse_model.dart';
// import 'package:TheWord/providers/verse_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import '../../providers/settings_provider.dart';
//
// class SelectableTextHighlight extends StatefulWidget {
//   final List<Map<String, dynamic>> verses; // List of verses
//   final TextStyle style;
//
//   const SelectableTextHighlight({
//     Key? key,
//     required this.verses,
//     required this.style,
//   }) : super(key: key);
//
//   @override
//   _SelectableTextHighlightState createState() => _SelectableTextHighlightState();
// }
//
// class _SelectableTextHighlightState extends State<SelectableTextHighlight> {
//   List<String> highlightedVerses = [];
//   Map<String, dynamic> savedVerses = {};
//   String? _token;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserToken();
//   }
//
//   Future<void> _loadUserToken() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _token = prefs.getString('token');
//     });
//     if (_token != null) {
//       await _loadSavedVerses();
//     }
//   }
//
//   Future<void> _toggleVerse(String verseId, String text, {String note = ''}) async {
//     if (_token == null) return;
//
//     if (savedVerses.containsKey(verseId)) {
//       print(savedVerses[verseId]);
//       await _unsaveVerse(savedVerses[verseId]['UserVerseID'].toString(), verseId);
//     } else {
//       await _saveVerse(verseId, text, note: note);
//     }
//   }
//
//   Future<void> _saveVerse(String verseId, String text, {String note = ''}) async {
//     if (_token == null) return;
//
//     final verseData = {
//       'VerseID': verseId,
//       'Content': text,
//       'Note': note,
//     };
//
//     final response = await http.post(
//       Uri.parse('http://billyrigdon.dev:8110/verses/save'),
//       headers: {
//         'Authorization': 'Bearer $_token',
//         'Content-Type': 'application/json',
//       },
//       body: json.encode(verseData),
//     );
//
//     if (response.statusCode == 200) {
//       final responseBody = json.decode(response.body);
//       final userVerseID = responseBody['userVerseID'];
//
//       print('Saved successfully: $verseId with UserVerseID: $userVerseID');
//       setState(() {
//         savedVerses[verseId] = {'UserVerseID': userVerseID, 'text': text, 'note': note};
//       });
//     } else {
//       print('Failed to save note: ${response.body}');
//     }
//   }
//
//
//   Future<void> _unsaveVerse(String userVerseId, String verseId) async {
//     if (_token == null) return;
//
//     final response = await http.delete(
//       Uri.parse('http://billyrigdon.dev:8110/verses/$userVerseId'),
//       headers: {
//         'Authorization': 'Bearer $_token',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       print('Unsaved successfully: $verseId');
//       setState(() {
//         savedVerses.remove(verseId);
//       });
//     } else {
//       print('Failed to unsave note: ${response.body}');
//     }
//   }
//
//   Future<void> _loadSavedVerses() async {
//     if (_token == null) return;
//
//     final response = await http.get(
//       Uri.parse('http://billyrigdon.dev:8110/verses/saved'),
//       headers: {'Authorization': 'Bearer $_token'},
//     );
//
//     if (response.statusCode == 200) {
//       final List<dynamic> savedVersesList = json.decode(response.body);
//       setState(() {
//         savedVerses = {
//           for (var verse in savedVersesList) verse['VerseID']: verse
//         };
//       });
//       print('Loaded saved verses: $savedVerses');
//     } else {
//       print('Failed to load saved verses: ${response.body}');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
//     var verseProvider = Provider.of<VerseProvider>(context, listen: false);
//     return ListView.builder(
//       itemCount: widget.verses.length,
//       itemBuilder: (context, index) {
//         final verse = widget.verses[index];
//         final verseId = verse['id'];
//         final verseText = verse['text'];
//         // final isHighlighted = highlightedVerses.contains(verseId);
//         var isHighlighted = savedVerses.containsKey(verseId);
//
//         return GestureDetector(
//           onLongPress: () {
//             _toggleVerse(verseId, verseText);
//           },
//           child: Container(
//             padding: const EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: isHighlighted ? settingsProvider.highlightColor : Colors.transparent,
//               borderRadius: BorderRadius.circular(12.0),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   verseText,
//                   style: isHighlighted
//                       ? TextStyle(fontSize: 16, color: settingsProvider.getFontColor(settingsProvider.highlightColor!))
//                       : widget.style,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
// selectable_text_highlight.dart
// selectable_text_highlight.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/verse_provider.dart';

class SelectableTextHighlight extends StatefulWidget {
  final List<Map<String, dynamic>> verses;
  final TextStyle style;

  const SelectableTextHighlight({
    Key? key,
    required this.verses,
    required this.style,
  }) : super(key: key);

  @override
  _SelectableTextHighlightState createState() => _SelectableTextHighlightState();
}

class _SelectableTextHighlightState extends State<SelectableTextHighlight> {
  @override
  void initState() {
    super.initState();
  }

  void _toggleVerse(VerseProvider verseProvider, String verseId, String text) {
    print(verseId);
    if (verseProvider.isVerseSaved(verseId.toString())) {
      print('IS SAVED--------------------------------------------');
      final userVerseId = verseProvider.getSavedVerseUserVerseID(verseId.toString());
      if (userVerseId != null) {
        print('UNSAVING------------------------------------------');
        verseProvider.unsaveVerse(userVerseId.toString());
      }
    } else {
      print("------------------------------------SAVING");
      verseProvider.saveVerse(verseId, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final verseProvider = Provider.of<VerseProvider>(context);

    return ListView.builder(
      itemCount: widget.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.verses[index];
        print(verse);
        final verseId = verse['id'];
        final verseText = verse['text'];
        final isHighlighted = verseProvider.isVerseSaved(verseId);
        print(verseId);
        return GestureDetector(
          onLongPress: () {
            _toggleVerse(verseProvider, verseId, verseText);
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isHighlighted ? settingsProvider.highlightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verseText,
                  style: isHighlighted
                      ? TextStyle(fontSize: 16, color: settingsProvider.getFontColor(settingsProvider.highlightColor!))
                      : widget.style,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
