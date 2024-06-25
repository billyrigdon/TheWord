import 'package:TheWord/screens/book_list.dart';
import 'package:TheWord/screens/main_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:TheWord/providers/notification_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/verse_provider.dart';
import '../shared/widgets/dynamic_search_bar.dart';
import '../shared/widgets/verse_card.dart';
import 'comment_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _versesScrollController = ScrollController();
  Color? fontColor;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onVersesScroll);
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    verseProvider.fetchSavedVerses(reset: true); // Initial fetch
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _versesScrollController.dispose();
    super.dispose();
  }

  void _onVersesScroll() {
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    if (_versesScrollController.position.pixels >=
        _versesScrollController.position.maxScrollExtent - 200) {
      verseProvider.fetchSavedVerses(); // Fetch more data when close to bottom
    }
  }

  Future<void> _onRefresh() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    await friendProvider.fetchFriends();
    await friendProvider.fetchSuggestedFriends();
    await verseProvider.fetchSavedVerses(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final notificationsProvider = Provider.of<NotificationProvider>(context);
    final verseProvider = Provider.of<VerseProvider>(context);

    MaterialColor? currentColor = settingsProvider.currentColor;
    var accentColor = settingsProvider.getFontColor(currentColor!);
    fontColor = settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.white : Colors.black;


    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 36,
                    child: DynamicSearchBar(
                      searchType: SearchType
                          .Profile, // Choose the appropriate search type
                      fontColor: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                settingsProvider.logout();
                friendProvider.reset();
                Provider.of<VerseProvider>(context,
                    listen: false)
                    .reset();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MainAppScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8.0),
          children: [
            friendProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (friendProvider.suggestedFriends.isNotEmpty)
                            const Text(
                              'Make new friends',
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      if (friendProvider.suggestedFriends.isNotEmpty)
                        _buildSuggestedFriends(friendProvider, settingsProvider,
                            notificationsProvider),
                      const Divider(height: 20, color: Colors.black),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'My friends',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      _buildFriendList(friendProvider, settingsProvider),
                    ],
                  ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Saved Verses',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            verseProvider.savedVerses.isEmpty && !verseProvider.isLoading
                ? const Center(child: Text('No saved verses'))
                : _buildSavedVersesList(verseProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedFriends(
      FriendProvider friendProvider,
      SettingsProvider settingsProvider,
      NotificationProvider notificationsProvider) {
    return friendProvider.suggestedFriends.isEmpty
        ? const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'No suggested friends at the moment.',
        style: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.italic,
        ),
      ),
    )
        : ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friendProvider.suggestedFriends.length,
      itemBuilder: (context, index) {
        final suggestedFriend = friendProvider.suggestedFriends[index];
        var theme = Theme.of(context);
        final backgroundColor = theme.brightness == Brightness.light
            ? theme.cardColor.withOpacity(0.9)
            : theme.cardColor.withOpacity(0.7);
        final cardWidth = MediaQuery.of(context).size.width * 0.95;

        return Center(
          child: Card(
            margin: const EdgeInsets.all(8.0),
            color: backgroundColor,
            elevation: 5,
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestedFriend.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: fontColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${suggestedFriend.mutualFriends} mutual friends',
                        style: TextStyle(
                          fontSize: 14,
                          color: fontColor,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await notificationsProvider
                            .sendFriendRequest(suggestedFriend.userID);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Friend request sent to ${suggestedFriend.username}'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to send friend request to ${suggestedFriend.username}'),
                            ),
                          );
                        }
                      },
                      child: Text(
                        notificationsProvider.isFriendRequested(
                            suggestedFriend.userID)
                            ? 'Friend Request Sent'
                            : 'Add Friend',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildFriendList(
      FriendProvider friendProvider, SettingsProvider settingsProvider) {
    return friendProvider.friends.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'You have no friends added yet.',
              style: TextStyle(
                fontSize: 16.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              var theme = Theme.of(context);
              final backgroundColor = theme.brightness == Brightness.light
                  ? theme.cardColor.withOpacity(0.9)
                  : theme.cardColor.withOpacity(0.7);
              final cardWidth = MediaQuery.of(context).size.width * 0.95;

              return Center(
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  color: backgroundColor,
                  elevation: 5,
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: fontColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${friend.mutualFriends} mutual friends',
                              style: TextStyle(
                                fontSize: 14,
                                color: fontColor,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              await friendProvider.removeFriend(friend.userID);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${friend.username} has been removed from your friends'),
                                ),
                              );
                            },
                            child: const Text('Remove'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSavedVersesList(VerseProvider verseProvider) {
    return ListView.builder(
      controller: _versesScrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: verseProvider.savedVerses.length +
          (verseProvider.hasMoreSavedVerses ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == verseProvider.savedVerses.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final verse = verseProvider.savedVerses[index];
        int userVerseId = verse['UserVerseID'];
        bool isPublished = verse['is_published'] ?? false;

        return Dismissible(
          key: Key(verse['VerseID'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            verseProvider.unsaveVerse(userVerseId.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verse removed')),
            );
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
                await verseProvider.saveNote(
                  verse['VerseID'].toString(),
                  verse['UserVerseID'].toString(),
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
                : (note) =>
                    _publishVerse(context, verse["VerseID"], userVerseId, note),
            onUnpublish: isPublished
                ? () => _unpublishVerse(context, userVerseId)
                : null,
          ),
        );
      },
    );
  }

  void _navigateToComments(BuildContext context, verse) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
    );
  }

  Future<void> _publishVerse(
      BuildContext context, verseId, int userVerseId, String note) async {
    final verseProvider = Provider.of<VerseProvider>(context, listen: false);
    try {
      await verseProvider.saveNote(verseId, userVerseId.toString(), note);
      final success = await verseProvider.publishVerse(userVerseId.toString());
      if (success) {
        verseProvider.updateVersePublishStatus(userVerseId, true);
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
      verseProvider.updateVersePublishStatus(userVerseId, false);
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
