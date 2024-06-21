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
