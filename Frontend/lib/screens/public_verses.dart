import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'comment_screen.dart';

class PublicVersesScreen extends StatefulWidget {
  @override
  _PublicVersesScreenState createState() => _PublicVersesScreenState();
}

class _PublicVersesScreenState extends State<PublicVersesScreen> {
  List verses = [];
  int currentPage = 1;
  final int pageSize = 10;
  bool isLoading = false;
  Map<int, int> likesCount = {};

  @override
  void initState() {
    super.initState();
    fetchVerses();
  }

  Future<void> fetchVerses({bool reset = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    if (reset) {
      verses = [];
      currentPage = 1;
    }

    final response = await http.get(Uri.parse(
        'http://billyrigdon.dev:8110/verses/public?page=$currentPage&pageSize=$pageSize'));
    if (response.statusCode == 200) {
      List newVerses = json.decode(response.body);
      setState(() {
        verses.addAll(newVerses);
        for (var verse in newVerses) {
          getLikesCount(verse['UserVerseID']).then((count) {
            setState(() {
              likesCount[verse['UserVerseID']] = count;
            });
          });
        }
        currentPage++;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load verses');
    }
  }

  Future<void> toggleLike(int userVerseId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('http://billyrigdon.dev:8110/verse/$userVerseId/toggle-like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      int newLikesCount = await getLikesCount(userVerseId);
      setState(() {
        likesCount[userVerseId] = newLikesCount;
      });
    } else {
      throw Exception('Failed to toggle like');
    }
  }

  Future<int> getLikesCount(int userVerseId) async {
    final response = await http.get(
        Uri.parse('http://billyrigdon.dev:8110/verse/$userVerseId/likes'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['likes_count'];
    } else {
      throw Exception('Failed to get likes count');
    }
  }

  void navigateToComments(verse) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(verse: verse)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            fetchVerses();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final verse = verses[index];
            int userVerseId = verse['UserVerseID'];
            return ListTile(
              title: Text(verse['Verse']),
              subtitle: Text('${verse['Content']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<int>(
                    future: getLikesCount(userVerseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(likesCount[userVerseId]?.toString() ?? '0');
                      } else {
                        return Text(likesCount[userVerseId]?.toString() ?? '0');
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    onPressed: () async {
                      await toggleLike(userVerseId);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: () => navigateToComments(verse),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
