import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/verse_provider.dart';
import '../shared/widgets/verse_card.dart';
import 'comment_screen.dart';

class SavedVersesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final verseProvider = Provider.of<VerseProvider>(context);

    return Scaffold(
      body: verseProvider.savedVerses.isEmpty
          ? const Center(child: Text('No saved verses'))
          : ListView.builder(
        itemCount: verseProvider.savedVerses.length,
        itemBuilder: (context, index) {
          final verse = verseProvider.savedVerses[index];
          int userVerseId = verse['UserVerseID'];
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
              verseProvider.unsaveVerse(userVerseId.toString());
            },
            child: VerseCard(
              verseId: verse['VerseID'],
              note: verse['Note'] ?? '',
              likesCount: verseProvider.likesCount[userVerseId] ?? 0,
              commentCount:
              verseProvider.commentCount[userVerseId] ?? 0,
              onLike: () {}, // No like button for saved verses
              onComment: () => _navigateToComments(context, verse),
              isSaved: true,
              onSaveNote: (note) => verseProvider.saveNote(
                verse['VerseID'].toString(),
                verse['UserVerseID'].toString(),
                note,
              ),
            ),
          );
        },
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
