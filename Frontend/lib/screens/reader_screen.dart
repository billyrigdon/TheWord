import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import '../shared/widgets/highlight_text.dart';

class ReaderScreen extends StatefulWidget {
  final String chapterId;
  final String chapterName;
  final List<dynamic> chapterIds;
  final List<String> chapterNames;

  const ReaderScreen({
    required this.chapterId,
    required this.chapterName,
    required this.chapterIds,
    required this.chapterNames,
  });

  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  late PageController _pageController;
  Map<String, List<Map<String, dynamic>>> _chapterContents = {};
  bool isLoading = true;
  String chapterName = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.chapterIds.indexOf(widget.chapterId),
    );
    _fetchChapterContent(widget.chapterId);
    chapterName = widget.chapterName;
  }

  List<Map<String, dynamic>> parseBibleContent(String content) {
    try {
      // Assume content is a JSON string and parse it
      final parsedData = jsonDecode(content);

      // Ensure the parsed data is a list
      if (parsedData is List) {
        return List<Map<String, dynamic>>.from(
            parsedData.map((item) => Map<String, dynamic>.from(item)));
      } else if (parsedData is Map) {
        return [Map<String, dynamic>.from(parsedData)];
      } else {
        print('Unexpected data format: $parsedData');
        return [];
      }
    } catch (e) {
      print('Failed to parse content: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _chapterContents = {};
    super.dispose();
  }

  List<Map<String, dynamic>> extractVerses(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> verses = [];

    for (var item in data) {
      if (item['name'] == 'para' && item['items'] is List) {
        for (var subItem in item['items']) {
          if (subItem['name'] == 'verse' && subItem['attrs'] is Map) {
            String verseId = subItem['attrs']['sid'] ?? subItem['attrs']['verseId'] ?? '';
            String verseText = '';

            for (var textItem in subItem['items']) {
              if (textItem['type'] == 'text') {
                verseText += textItem['text'];
              }
            }

            if (verseId.isNotEmpty && verseText.isNotEmpty) {
              _addOrUpdateVerse(verses, verseId, verseText);
            }
          } else if (subItem['type'] == 'text' && subItem['attrs'] is Map) {
            String verseText = subItem['text'] ?? '';
            String verseId = subItem['attrs']['verseId'] ?? '';

            if (verseId.isNotEmpty && verseText.isNotEmpty) {
              _addOrUpdateVerse(verses, verseId, verseText);
            }
          }
        }
      }
    }

    return verses;
  }

  void _addOrUpdateVerse(List<Map<String, dynamic>> verses, String verseId, String verseText) {
    var existingVerse = verses.firstWhere(
          (verse) => verse['id'] == verseId,
      orElse: () => {},
    );

    if (existingVerse.isNotEmpty) {
      existingVerse['text'] += ' ${verseText.trim()}';
    } else {
      verses.add({'id': verseId, 'text': verseText.trim()});
    }
  }

  Future<void> _fetchChapterContent(String chapterId) async {
    var settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    String translationId = settingsProvider.currentTranslationId!;

    setState(() {
      isLoading = true;
    });

    if (_chapterContents.containsKey(chapterId)) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse(
          'https://api.scripture.api.bible/v1/bibles/$translationId/chapters/$chapterId?content-type=json'),
      headers: {'api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> parsedContent = parseBibleContent(
          jsonEncode(data['data']['content']));
      List<Map<String, dynamic>> verses = extractVerses(parsedContent);

      setState(() {
        _chapterContents[chapterId] = verses;
        isLoading = false;
      });
    } else {
      setState(() {
        _chapterContents[chapterId] = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(chapterName),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.chapterIds.length,
        onPageChanged: (index) {
          final currentChapterId = widget.chapterIds[index];
          final currentChapterName = widget.chapterNames[index];
          _fetchChapterContent(currentChapterId);
          setState(() {
            chapterName = currentChapterName;
          });
        },
        itemBuilder: (context, index) {
          final chapterId = widget.chapterIds[index];
          return Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableTextHighlight(
                style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16),
                verses: _chapterContents[chapterId] ?? [],
              ),
            ),
          );
        },
      ),
    );
  }
}

