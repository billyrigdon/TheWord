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
  int likesCount = 0;

  @override
  void initState() {
    verse = widget.verse;
    super.initState();
    fetchComments();
    fetchLikesCount();
  }

  Future<void> fetchComments() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/comments'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      if (response.body != null) {
        setState(() {
        comments = json.decode(response.body) ?? [];
        isLoading = false;
      });
      } else {
        setState(() {
          comments = [];
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load comments');
    }
  }

  Future<void> fetchLikesCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/likes'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        likesCount = json.decode(response.body)['likes_count'];
      });
    } else {
      throw Exception('Failed to load likes count');
    }
  }

  Future<void> toggleLike() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/toggle-like'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      fetchLikesCount();
    } else {
      throw Exception('Failed to toggle like');
    }
  }

  Future<void> addComment(String content, {int? parentCommentID}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    final response = await http.post(
      Uri.parse(
          'http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/comment${parentCommentID != null ? "?parentCommentID=$parentCommentID" : ""}'),
      headers: {'Authorization': 'Bearer $token'},
      body: json.encode({'content': content}),
    );
    if (response.statusCode == 200) {
      await fetchComments();
    } else {
      throw Exception('Failed to add comment');
    }
  }

  Future<void> updateComment(int commentID, String content) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/comment/$commentID'),
      headers: {'Authorization': 'Bearer $token'},
      body: json.encode({'content': content}),
    );
    if (response.statusCode == 200) {
      await fetchComments();
    } else {
      throw Exception('Failed to update comment');
    }
  }

  Future<void> deleteComment(int commentID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/verse/${verse["UserVerseID"]}/comment/$commentID'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      await fetchComments();
    } else {
      throw Exception('Failed to delete comment');
    }
  }

  void showAddCommentDialog(BuildContext context, {int? parentCommentID}) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Enter your comment here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await addComment(commentController.text, parentCommentID: parentCommentID);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showEditCommentDialog(BuildContext context, int commentID, String currentContent) {
    final commentController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Edit your comment here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await updateComment(commentID, commentController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              verse['VerseID'],
              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verse['Content'],
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                const SizedBox(height: 16),
                Text(
                  verse['Note'],
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(likesCount.toString()),
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      onPressed: toggleLike,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.comment),
                      onPressed: () => showAddCommentDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                if (comment['ParentCommentID'] == null || comment['ParentCommentID'] == 0) {
                  return _buildCommentCard(comment, 1, comments);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int depth, List<dynamic> allComments) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    var childComments = allComments.where((c) => c['ParentCommentID'] == comment['CommentID']).toList();
    final commentUserID = comment['UserID'];

    return Stack(
      children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: settingsProvider.currentThemeMode == ThemeMode.dark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  boxShadow: const [
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
                    const SizedBox(height: 4.0),
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
                        if (commentUserID == Provider.of<SettingsProvider>(context, listen: false).userId)
                          ...[
                            IconButton(
                              icon: Icon(Icons.edit, color: settingsProvider.currentColor),
                              onPressed: () {
                                showEditCommentDialog(context, comment['CommentID'], comment['Content']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: settingsProvider.currentColor),
                              onPressed: () {
                                _confirmDeleteComment(comment['CommentID']);
                              },
                            ),
                          ]
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

  void _confirmDeleteComment(int commentID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await deleteComment(commentID);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
