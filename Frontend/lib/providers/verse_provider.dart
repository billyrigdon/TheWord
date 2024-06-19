// verse_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VerseProvider with ChangeNotifier {
  List<dynamic> publicVerses = [];
  List<dynamic> savedVerses = [];
  Map<int, int> likesCount = {};
  Map<int, int> commentCount = {};
  bool isLoading = false;
  String? _token;

  VerseProvider() {
  }

  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    fetchPublicVerses(reset: true);
    fetchSavedVerses();
  }

  reset() {
    publicVerses = [];
    savedVerses = [];
    likesCount = {};
    commentCount = {};
    bool isLoading = false;
    _token = '';
  }

  Future<void> saveVerse(String verseId, String text, {String note = ''}) async {
    if (_token == null) return;

    final verseData = {
      'VerseID': verseId,
      'Content': text,
      'Note': note,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/verses/save'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode(verseData),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final userVerseID = responseBody['userVerseID'];
      savedVerses.add({
        'UserVerseID': userVerseID,
        'VerseID': verseId,
        'Content': text,
        'Note': note,
      });
      notifyListeners();
    } else {
      print('Failed to save verse: ${response.body}');
    }
  }

  bool isVerseSaved(String verseId) {
    return savedVerses.any((verse) => verse['VerseID'] == verseId);
  }

  String? getSavedVerseUserVerseID(String verseId) {
    final savedVerse = savedVerses.firstWhere(
          (verse) => verse['VerseID'] == verseId,
      orElse: () => null,
    );
    return savedVerse?['UserVerseID'].toString();
  }

  Future<void> fetchPublicVerses({bool reset = false, int pageSize = 10}) async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    if (reset) {
      publicVerses = [];
    }

    final currentPage = (publicVerses.length ~/ pageSize) + 1;
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verses/public?page=$currentPage&pageSize=$pageSize'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      print(response.body.toString());
      print('SUCCESS');
      List newVerses = json.decode(response.body) ?? [];
      publicVerses.addAll(newVerses);
      for (var verse in newVerses) {
        int userVerseId = verse['UserVerseID'];
        _getLikesCount(userVerseId);
        _getCommentCount(userVerseId);
      }
      notifyListeners();
    } else {
      print('Failed to load public verses: ${response.body}');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSavedVerses() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verses/saved'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> verses = json.decode(response.body);
      verses.removeWhere((verse) => verse['VerseID'] == null || !verse['VerseID'].contains('.'));
      verses.sort((a, b) {
        List<String> aParts = a['VerseID'].split('.');
        List<String> bParts = b['VerseID'].split('.');
        int bookComparison = aParts[0].compareTo(bParts[0]);
        if (bookComparison != 0) return bookComparison;
        int chapterComparison = int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
        return chapterComparison != 0 ? chapterComparison : int.parse(aParts[2]).compareTo(int.parse(bParts[2]));
      });

      savedVerses = verses;
      for (var verse in verses) {
        int userVerseId = verse['UserVerseID'];
        _getLikesCount(userVerseId);
        _getCommentCount(userVerseId);
      }
      notifyListeners();
    } else {
      print('Failed to load saved verses: ${response.body}');
    }
    notifyListeners();
  }

  Future<void> _getLikesCount(int userVerseId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/likes'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      likesCount[userVerseId] = json.decode(response.body)['likes_count'];
      notifyListeners();
    } else {
      print('Failed to fetch likes count: ${response.body}');
    }
  }

  Future<void> _getCommentCount(int userVerseId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/comments/count'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      commentCount[userVerseId] = json.decode(response.body)['comment_count'];
      notifyListeners();
    } else {
      print('Failed to fetch comments count: ${response.body}');
    }
  }

  Future<void> toggleLike(int userVerseId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/toggle-like'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      _getLikesCount(userVerseId);
    } else {
      print('Failed to toggle like: ${response.body}');
    }
  }

  Future<void> unsaveVerse(String userVerseId) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/verses/$userVerseId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      savedVerses.removeWhere((verse) => verse['UserVerseID'] == int.parse(userVerseId));
      fetchSavedVerses();
      fetchPublicVerses(reset: true);
      notifyListeners();
    } else {
      print('Failed to unsave verse: ${response.body}');
    }
  }

  Future<void> saveNote(String verseId, String userVerseId, String note) async {
    final existingVerse = savedVerses.firstWhere(
          (element) => element['VerseID'] == verseId,
      orElse: () => null,
    );

    if (existingVerse == null) {
      print('Verse not found for verseId: $verseId');
      return;
    }

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/verses/$userVerseId'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'note': note}),
    );

    if (response.statusCode == 200) {
      existingVerse['Note'] = note;
      notifyListeners();
    } else {
      print('Failed to update note: ${response.body}');
    }
  }

  Future<bool> publishVerse(String userVerseId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/publish'),
        headers: <String, String>{
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, bool>{
          'is_published': true,
        }),
      );
      print(response.toString());
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        print('Failed to publish verse: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Failed to publish verse: $error');
      return false;
    }
  }

  Future<bool> unpublishVerse(String userVerseId) async {

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/verse/$userVerseId/unpublish'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token', // Include the token here
        },
        body: jsonEncode(<String, bool>{
          'is_published': false,
        }),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        print('Failed to unpublish verse: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('Failed to unpublish verse: $error');
      return false;
    }
  }

}
