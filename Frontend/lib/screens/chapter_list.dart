import 'dart:convert';

import 'package:TheWord/screens/reader_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChapterListScreen extends StatefulWidget {
  final String bookId;
  final String bookName;

  const ChapterListScreen({super.key, required this.bookId, required this.bookName});

  @override
  ChapterListScreenState createState() => ChapterListScreenState();
}


class ChapterListScreenState extends State<ChapterListScreen> {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  List<dynamic> chapters = [];

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles/bba9f40183526463-01/books/${widget.bookId}/chapters'),
      headers: {'api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        chapters = data['data'];
      });
    } else {
      throw Exception('Failed to load chapters');
    }
  }

  List<dynamic> getRealChapters(List<dynamic> chapters) {
    return chapters.skip(1).toList(); // Skip the first element which is the intro
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> realChapters = getRealChapters(chapters);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} Chapters'),
      ),
      body: realChapters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: realChapters.length,
        itemBuilder: (context, index) {
          int chapterIndex = index + 1; // Adjust index to reflect the actual chapter number
          return ListTile(
            title: Text('Chapter $chapterIndex'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(
                    chapterId: realChapters[index]['id']!,
                    chapterName: 'Chapter $chapterIndex',
                    chapterIds: realChapters.map((c) => c['id']!).toList(),
                    chapterNames: realChapters
                        .asMap()
                        .entries
                        .map((entry) => 'Chapter ${entry.key + 1}')
                        .toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}