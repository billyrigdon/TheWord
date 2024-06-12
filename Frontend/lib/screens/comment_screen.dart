
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';

class CommentsScreen extends StatefulWidget {
  final dynamic verse;

  CommentsScreen({required this.verse});

  @override
  State<StatefulWidget> createState() => CommentsScreenState();
}

class CommentsScreenState extends State<CommentsScreen> {
  var verse;
  List comments = [];
  bool isLoading = false;

  @override
  void initState() {
    verse = widget.verse;
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
        Uri.parse('http://billyrigdon.dev:8110/verse/${verse["UserVerseID"]}/comments'));
    if (response.statusCode == 200) {
      setState(() {
        comments = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load comments');
    }
  }

  Future<void> addComment(String content, {int? parentCommentID}) async {
    print(parentCommentID);
    print(content);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('http://billyrigdon.dev:8110/verse/${verse["UserVerseID"]}/comment${parentCommentID != null ? "?parentCommentID=$parentCommentID" : ""}'),
      headers: {'Authorization': 'Bearer $token'},
      body: json.encode({'content': content}),
    );
    if (response.statusCode == 200) {
      await fetchComments();
    } else {
      throw Exception('Failed to add comment');
    }
  }

  void showAddCommentDialog(BuildContext context, {int? parentCommentID}) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(hintText: 'Enter your comment here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await addComment(commentController.text, parentCommentID: parentCommentID);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              verse['Content'], // Display the verse content
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              verse['Note'], // Display the verse content
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                if (comment['ParentCommentID'] == null || comment['ParentCommentID'] == 0) {
                  // Render top-level comments
                  return _buildCommentCard(comment, 1, comments);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCommentDialog(context),
        child: Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int depth, List<dynamic> allComments) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    var childComments = allComments.where((c) => c['ParentCommentID'] == comment['CommentID']).toList();

    return Stack(
      children: [
        // Container for the left line
    Positioned(
            top: 0,
            bottom: 0,
            left: 0.0,
            child: Container(
              width: 3.0,
              color: settingsProvider.currentColor,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: depth + 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(left: depth + 12.0),
                padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['Username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      comment['Content'],
                      style: TextStyle(
                        color: settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.reply, color: settingsProvider.currentColor),
                          onPressed: () {
                            showAddCommentDialog(context, parentCommentID: comment['CommentID']);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (childComments.isNotEmpty)
                ...childComments.map((child) => _buildCommentCard(child, depth + 1, allComments)).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

