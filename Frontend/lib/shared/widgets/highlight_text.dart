// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/settings_provider.dart';
// import '../../providers/verse_provider.dart';
//
// class SelectableTextHighlight extends StatefulWidget {
//   final List<Map<String, dynamic>> verses;
//   final TextStyle style;
//   int? currentVerseIndex;
//
//   SelectableTextHighlight(
//       {Key? key,
//       required this.verses,
//       required this.style,
//       this.currentVerseIndex})
//       : super(key: key);
//
//   @override
//   _SelectableTextHighlightState createState() =>
//       _SelectableTextHighlightState();
// }
//
// class _SelectableTextHighlightState extends State<SelectableTextHighlight> {
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   void _toggleVerse(VerseProvider verseProvider, String verseId, String text) async {
//     print(verseId);
//     if (verseProvider.isVerseSaved(verseId.toString())) {
//       print('IS SAVED--------------------------------------------');
//       final userVerseId =
//           verseProvider.getSavedVerseUserVerseID(verseId.toString());
//       if (userVerseId != null) {
//         print('UNSAVING------------------------------------------');
//         await verseProvider.unsaveVerse(userVerseId.toString());
//       }
//     } else {
//       print("------------------------------------SAVING");
//       await verseProvider.saveVerse(verseId.toString(), text);
//     }
//   }
//
//   bool _isNumeric(String str) {
//     if (str.isEmpty) return false;
//     return double.tryParse(str) != null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final settingsProvider = Provider.of<SettingsProvider>(context);
//     final verseProvider = Provider.of<VerseProvider>(context);
//
//     return ListView.builder(
//       itemCount: widget.verses.length,
//       itemBuilder: (context, index) {
//         final verse = widget.verses[index];
//         final verseId = verse['id'];
//         final verseText = verse['text'];
//         final isHighlighted = verseProvider.isVerseSaved(verseId);
//
//         return GestureDetector(
//           onDoubleTap: () {
//             if (!_isNumeric(verseText)) {
//               _toggleVerse(verseProvider, verseId.toString(), verseText);
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: isHighlighted
//                   ? settingsProvider.highlightColor
//                   : Colors.transparent,
//               borderRadius: BorderRadius.circular(12.0),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SelectableText(
//                   verseText,
//                   style: isHighlighted
//                       ? TextStyle(
//                           fontSize: 16,
//                           color: settingsProvider
//                               .getFontColor(settingsProvider.highlightColor!),
//                           fontWeight: widget.currentVerseIndex == index
//                               ? FontWeight.bold
//                               : FontWeight.normal)
//                       : TextStyle(
//                           fontSize: 16,
//                           fontWeight: widget.currentVerseIndex == index
//                               ? FontWeight.bold
//                               : FontWeight.normal),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/verse_provider.dart';

class SelectableTextHighlight extends StatefulWidget {
  final List<Map<String, dynamic>> verses;
  final TextStyle style;
  int? currentVerseIndex;

  SelectableTextHighlight({
    Key? key,
    required this.verses,
    required this.style,
    this.currentVerseIndex,
  }) : super(key: key);

  @override
  _SelectableTextHighlightState createState() =>
      _SelectableTextHighlightState();
}

class _SelectableTextHighlightState extends State<SelectableTextHighlight> {
  @override
  void initState() {
    super.initState();
  }

  void _toggleVerse(VerseProvider verseProvider, String verseId, String text) async {
    print(verseId);
    if (verseProvider.isVerseSaved(verseId.toString())) {
      print('IS SAVED--------------------------------------------');
      final userVerseId =
      verseProvider.getSavedVerseUserVerseID(verseId.toString());
      if (userVerseId != null) {
        print('UNSAVING------------------------------------------');
        await verseProvider.unsaveVerse(userVerseId.toString());
      }
    } else {
      print("------------------------------------SAVING");
      await verseProvider.saveVerse(verseId.toString(), text);
    }
  }

  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return double.tryParse(str) != null;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final verseProvider = Provider.of<VerseProvider>(context);

    return ListView.builder(
      itemCount: widget.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.verses[index];
        final verseId = verse['id'];
        final verseText = verse['text'];
        final verseLabel = verseId.toString().split('.').last;
        final isHighlighted = verseProvider.isVerseSaved(verseId);
        final isCurrentVerse = widget.currentVerseIndex == index;

        return GestureDetector(
          onDoubleTap: () {
            if (!_isNumeric(verseText)) {
              _toggleVerse(verseProvider, verseId.toString(), verseText);
            }
          },
          child: !_isNumeric(verseText) ?
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? settingsProvider.highlightColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse number
                Container(
                  width: 30, // Adjust width as needed
                  child: Text(
                    verseLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Verse text
                Expanded(
                  child: SelectableText(
                    verseText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrentVerse ? FontWeight.bold : FontWeight.normal,
                      color: isHighlighted
                          ? settingsProvider.getFontColor(settingsProvider.highlightColor!)
                          : settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ): Container(),
        );
      },
    );
  }
}
