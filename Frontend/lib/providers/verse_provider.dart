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

    // Check if the verse is already saved.
    if (savedVerses.any((verse) => verse['VerseID'] == verseId)) {
      return;
    }

    // Add the verse to savedVerses before making the HTTP call.
    final verseEntry = {
      'UserVerseID': 0, // Placeholder, will be updated upon success.
      'VerseID': verseId,
      'Content': text,
      'Note': note,
    };

    savedVerses.add(verseEntry);
    notifyListeners();

    final verseData = {
      'VerseID': verseId,
      'Content': text,
      'Note': note,
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/verses/save'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(verseData),
      );

      print(response.body);

      if (response.statusCode == 200) {
        print('success--------------------------------------');
        final responseBody = json.decode(response.body);
        final userVerseID = responseBody['userVerseID'];
        print(responseBody.toString());

        // Update the saved verse with the actual userVerseID.
        verseEntry['UserVerseID'] = userVerseID;
        notifyListeners();
      } else {
        // If the request fails, remove the verse from savedVerses.
        savedVerses.removeWhere((verse) => verse['VerseID'] == verseId);
        notifyListeners();
      }
    } catch (e) {
      // Handle any exceptions and remove the verse from savedVerses.
      savedVerses.removeWhere((verse) => verse['VerseID'] == verseId);
      notifyListeners();
    }
  }


  bool isVerseSaved(String verseId) {
    return savedVerses.any((verse) => verse['VerseID'] == verseId);
  }

  getVerseByUserVerseId(String userVerseId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/verse/$userVerseId'),
      headers: {
        'Authorization': 'Bearer $_token'
      },

    );

    return json.decode(response.body);

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
      List newVerses = json.decode(response.body) ?? [];
      publicVerses.addAll(newVerses);
      for (var verse in newVerses) {
        int userVerseId = verse['UserVerseID'];
        _getLikesCount(userVerseId);
        _getCommentCount(userVerseId);
      }
      notifyListeners();
    } else {
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
    }
  }

  Future<void> saveNote(String verseId, String userVerseId, String note) async {
    final existingVerse = savedVerses.firstWhere(
          (element) => element['UserVerseID'] == userVerseId,
      orElse: () => null,
    );

    if (existingVerse == null) {
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
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (error) {
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
        return false;
      }
    } catch (error) {
      return false;
    }
  }

}
