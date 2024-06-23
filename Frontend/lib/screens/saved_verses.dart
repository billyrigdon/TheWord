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
          bool isPublished = verse['is_published'] ?? false; // Retrieve the is_published status

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
              verseContent: verse['Content'],
              likesCount: verseProvider.likesCount[userVerseId] ?? 0,
              commentCount: verseProvider.commentCount[userVerseId] ?? 0,
              onLike: () {},
              onComment: () => _navigateToComments(context, verse),
              isSaved: true,
              isPublished: isPublished,
              onSaveNote: (note) async {
                try {
                  print('onSaveNote');
                  await verseProvider.saveNote(
                    verse['UserVerseID'].toString(),
                    verse['VerseID'].toString(),
                    note,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verse saved successfully')),
                  );
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verse failed to save')),
                  );
                }
              },
              onPublish: isPublished
                  ? null
                  : (note) => _publishVerse(context, verse["VerseID"] , userVerseId, note),
              onUnpublish: isPublished
                  ? () => _unpublishVerse(context, userVerseId)
                  : null,
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

  Future<void> _publishVerse(BuildContext context, verseId, int userVerseId, String note) async {
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    try {
      await verseProvider.saveNote(verseId, userVerseId.toString(), note);

      final success = await verseProvider.publishVerse(userVerseId.toString());
      if (success) {
        verseProvider.init();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verse published successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish verse')),
        );
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save verse')),
      );
    }

  }

  Future<void> _unpublishVerse(BuildContext context, int userVerseId) async {
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    final success = await verseProvider.unpublishVerse(userVerseId.toString());
    if (success) {
      verseProvider.init();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verse unpublished successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unpublish verse')),
      );
    }
  }
}

