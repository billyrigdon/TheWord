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
    this.currentVerseIndex
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
                      ? TextStyle(fontSize: 16, color: settingsProvider.getFontColor(settingsProvider.highlightColor!), fontWeight: widget.currentVerseIndex == index ? FontWeight.bold : FontWeight.normal)
                      : TextStyle(fontSize: 16, fontWeight: widget.currentVerseIndex == index ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
