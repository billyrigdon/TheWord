import 'dart:convert';
import 'package:TheWord/screens/saved_verses.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/settings_provider.dart';
import '../services/chat_service.dart';
import '../shared/widgets/highlight_text.dart';

class ReaderScreen extends StatefulWidget {
  String chapterId;
  final String chapterName;
  final List<dynamic> chapterIds;
  final List<String> chapterNames;
  final String bookName;

  ReaderScreen(
      {required this.chapterId,
      required this.chapterName,
      required this.chapterIds,
      required this.chapterNames,
      required this.bookName});

  @override
  ReaderScreenState createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  late PageController _pageController;
  Map<String, List<Map<String, dynamic>>> _chapterContents = {};
  bool isLoading = true;
  bool isSummaryLoading = false; // Loading state for summary
  String chapterName = '';
  bool isReading = false;
  int currentVerseIndex = 0;
  FlutterTts flutterTts = FlutterTts();
  bool isPaused = false;
  bool isSkipping = false;
  ChatService chatService = ChatService(); // Initialize ChatService
  int currentPageIndex = 0;
  bool savedVersesActive = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.chapterIds.indexOf(widget.chapterId),
    );
    _fetchChapterContent(widget.chapterId);
    chapterName = widget.chapterName;

    flutterTts.setCompletionHandler(() {
      if (!isSkipping) {
        _readNextVerse();
      }
      isSkipping = false;
    });
    // Set TTS properties
    flutterTts.setSpeechRate(0.5); // Slower speech rate
    flutterTts.setPitch(1.0); // Default pitch
    flutterTts.setLanguage('en-US');
    flutterTts.awaitSpeakCompletion(true);
  }

  List<Map<String, dynamic>> parseBibleContent(String content) {
    try {
      final parsedData = jsonDecode(content);

      if (parsedData is List) {
        return List<Map<String, dynamic>>.from(
            parsedData.map((item) => Map<String, dynamic>.from(item)));
      } else if (parsedData is Map) {
        return [Map<String, dynamic>.from(parsedData)];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _chapterContents = {};
    flutterTts.stop();
    super.dispose();
  }

  List<Map<String, dynamic>> extractVerses(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> verses = [];

    for (var item in data) {
      if (item['name'] == 'para' && item['items'] is List) {
        for (var subItem in item['items']) {
          if (subItem['name'] == 'verse' && subItem['attrs'] is Map) {
            String verseId =
                subItem['attrs']['sid'] ?? subItem['attrs']['verseId'] ?? '';
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

  void _addOrUpdateVerse(
      List<Map<String, dynamic>> verses, String verseId, String verseText) {
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
    var settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    String translationId = settingsProvider.currentTranslationId!;

    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse(
          'https://api.scripture.api.bible/v1/bibles/$translationId/chapters/$chapterId?content-type=json'),
      headers: {'api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> parsedContent =
          parseBibleContent(jsonEncode(data['data']['content']));
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

  void _startReading() async {
    if (_chapterContents[widget.chapterId] != null &&
        _chapterContents[widget.chapterId]!.isNotEmpty) {
      setState(() {
        isReading = true;
        currentVerseIndex = 0;
      });
      _readVerse(currentVerseIndex);
    }
  }

  void _readVerse(int index) async {
    if (index == 0) {
      await _announceChapter(chapterName);
    }

    if (index < _chapterContents[widget.chapterId]!.length) {
      String verseText = _chapterContents[widget.chapterId]![index]['text'];
      // Check if verseText is an integer and skip if it is
      if (!_isNumeric(verseText)) {
        await flutterTts.speak(verseText);
        setState(() {
          currentVerseIndex = index;
        });
      } else {
        // Skip the verse if it is numeric and ensure no stack overflow
        _safeReadNextVerse(index);
      }
    } else {
      _fetchNextChapter();
    }
  }

  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return double.tryParse(str) !=
        null; // Check if the string can be parsed as a number
  }

  void _safeReadNextVerse(int currentIndex) {
    // Ensure we don't go into infinite recursion
    if (currentIndex + 1 < _chapterContents[widget.chapterId]!.length) {
      setState(() {
        currentVerseIndex = currentIndex + 1;
      });
      _readVerse(currentVerseIndex);
    } else {
      _fetchNextChapter();
    }
  }

  void _readNextVerse() async {
    if (currentVerseIndex + 1 < _chapterContents[widget.chapterId]!.length) {
      _readVerse(currentVerseIndex + 1);
    } else {
      _fetchNextChapter();
    }
  }

  void _pauseReading() {
    flutterTts.stop();
    setState(() {
      isPaused = true;
      isReading = false;
    });
  }

  void _resumeReading() {
    setState(() {
      isPaused = false;
      isReading = true;
    });
    _readVerse(currentVerseIndex);
  }

  void _skipReading() {
    flutterTts.stop();
    setState(() {
      isSkipping = true;
    });
    _readNextVerse();
  }

  Future<void> _fetchNextChapter() async {
    int currentIndex = widget.chapterIds.indexOf(widget.chapterId);
    if (currentIndex + 1 < widget.chapterIds.length) {
      final nextChapterId = widget.chapterIds[currentIndex + 1];
      final nextChapterName = widget.chapterNames[currentIndex + 1];

      // Ensure to fetch the content of the next chapter
      await _fetchChapterContent(nextChapterId);

      setState(() {
        isSkipping = false;
        currentVerseIndex = 0;
        widget.chapterId = nextChapterId;
        chapterName = nextChapterName;
        _pageController.jumpToPage(currentIndex + 1);
      });
      _readVerse(currentVerseIndex);
    } else {
      setState(() {
        isReading = false;
      });
    }
  }

  Future<void> _announceChapter(String chapterName) async {
    setState(() {
      isSkipping = true;
    });
    await flutterTts.speak(chapterName);
    setState(() {
      isSkipping = true;
    });
  }

  void _changePage(int direction) async {
    if (direction == -1 && currentPageIndex > 0) {
      currentPageIndex--;
    } else if (direction == 1 &&
        currentPageIndex < widget.chapterIds.length - 1) {
      currentPageIndex++;
    } else {
      return; // Don't change page if it's out of range
    }

    final currentChapterId = widget.chapterIds[currentPageIndex];
    final currentChapterName = widget.chapterNames[currentPageIndex];

    if (isReading) {
      flutterTts.stop();
    }

    setState(() {
      widget.chapterId = currentChapterId;
      chapterName = currentChapterName;
      currentVerseIndex = 0;
      // isLoading = true;
    });

    await _fetchChapterContent(currentChapterId);

    setState(() {
      isLoading = false;
    });

    _pageController.jumpToPage(currentPageIndex);

    if (isReading) {
      _resumeReading();
    }
  }

  void _summarizeContent({bool entireChapter = true}) async {
    setState(() {
      isSummaryLoading = true;
    });

    String content;
    content = _chapterContents[widget.chapterId]!
        .map((verse) => verse['text'])
        .join(' ');

    String summary = await chatService.getResponse(
        "Summarize and provide context and interpretations for the following content: $content");

    setState(() {
      isSummaryLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => SummaryModal(content: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    String bookName = widget.bookName;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !savedVersesActive,
        toolbarTextStyle: TextStyle(
            color: settingsProvider.currentThemeMode == ThemeMode.dark
                ? Colors.white
                : Colors.black),
        toolbarHeight: 30,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(
            color: settingsProvider.currentThemeMode == ThemeMode.dark
                ? Colors.white
                : Colors.black),
        actions: savedVersesActive
            ? [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        iconSize: 24,
                        padding: EdgeInsets.only(left:12),
                        icon: const Icon(Icons.arrow_back,),
                        onPressed: () {
                          setState(() {
                            savedVersesActive = false;
                          });
                        },
                      ),
                    ],
                  ),
                )
              ]
            : [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Center(
                      child: SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            bookName,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  color: settingsProvider.currentThemeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                  icon: Icon(isReading ? Icons.stop : Icons.play_arrow),
                  onPressed: () {
                    if (isReading) {
                      _pauseReading();
                    } else {
                      _startReading();
                    }
                  },
                ),
              ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: savedVersesActive
          ? SavedVersesScreen()
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.chapterIds.length,
                        onPageChanged: (index) {
                          if (isReading) {
                            flutterTts.stop();
                          }
                          final currentChapterId = widget.chapterIds[index];
                          final currentChapterName = widget.chapterNames[index];
                          _fetchChapterContent(currentChapterId);
                          setState(() {
                            widget.chapterId = currentChapterId;
                            chapterName = currentChapterName;
                            currentVerseIndex = 0;
                            currentPageIndex = index;
                          });
                          if (isReading) {
                            _resumeReading();
                          }
                        },
                        itemBuilder: (context, index) {
                          final chapterId = widget.chapterIds[index];
                          return Center(
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SelectableTextHighlight(
                                      style: theme.textTheme.bodyMedium!
                                          .copyWith(fontSize: 16),
                                      verses: _chapterContents[chapterId] ?? [],
                                      currentVerseIndex: currentVerseIndex,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    if (isReading)
                      Container(
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.pause),
                              onPressed: _pauseReading,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: _skipReading,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isSummaryLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: !savedVersesActive
          ? BottomAppBar(
              padding: EdgeInsets.zero,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.bookmark),
                        onPressed: () {
                          setState(() {
                            savedVersesActive = !savedVersesActive;
                          });
                        },
                        tooltip: 'Saved',
                      ),
                      Text('Saved', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_circle_left,
                      size: 40, // Slightly larger icon
                    ),
                    onPressed: () {
                      _changePage(-1); // Move to the previous page
                    },
                  ),
                  Text(chapterName, style: TextStyle(fontSize: 16)),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_circle_right,
                      size: 40, // Slightly larger icon
                    ),
                    onPressed: () {
                      _changePage(1); // Move to the next page
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.summarize),
                        onPressed: () {
                          _summarizeContent();
                        },
                        tooltip: 'Summarize',
                      ),
                      Text('Summarize', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class SummaryModal extends StatelessWidget {
  final String content;

  const SummaryModal({required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Summary'),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(data: content),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
