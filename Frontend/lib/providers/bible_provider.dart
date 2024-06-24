// // import 'package:flutter/material.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// //
// // class BibleProvider with ChangeNotifier {
// //   final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
// //   List<dynamic> _translations = [];
// //   List<dynamic> get translations => _translations;
// //
// //   Future<void> fetchTranslations() async {
// //     final response = await http.get(
// //       Uri.parse('https://api.scripture.api.bible/v1/bibles'),
// //       headers: {'api-key': apiKey},
// //     );
// //     print(response.body);
// //     if (response.statusCode == 200) {
// //       final data = json.decode(response.body);
// //       _translations = data['data'];
// //       notifyListeners();
// //     } else {
// //       throw Exception('Failed to load translations');
// //     }
// //   }
// //
// //   Future<void> fetchBooks() async {
// //
// //   }
// //
// // }
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class BibleProvider with ChangeNotifier {
//   final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
//   List<dynamic> _translations = [];
//   List<dynamic> _books = [];
//   List<dynamic> _filteredBooks = [];
//   Map<String, List<dynamic>> _chapters = {};
//   bool isLoadingBooks = false;
//   bool isLoadingChapters = false;
//
//   List<dynamic> get translations => _translations;
//   List<dynamic> get filteredBooks => _filteredBooks;
//   List<dynamic> get books => _books;
//   Map<String, List<dynamic>> get chapters => _chapters;
//
//   Future<void> fetchTranslations() async {
//     final response = await http.get(
//       Uri.parse('https://api.scripture.api.bible/v1/bibles'),
//       headers: {'api-key': apiKey},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       _translations = data['data'];
//       notifyListeners();
//     } else {
//       throw Exception('Failed to load translations');
//     }
//   }
//
//   Future<void> fetchBooks(String translationId) async {
//     isLoadingBooks = true;
//     notifyListeners();
//     final response = await http.get(
//       Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books'),
//       headers: {'api-key': apiKey},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       _books = data['data'];
//       notifyListeners();
//     } else {
//       throw Exception('Failed to load books');
//     }
//     isLoadingBooks = false;
//     notifyListeners();
//   }
//
//   Future<void> fetchChapters(String translationId, String bookId) async {
//     isLoadingChapters = true;
//     notifyListeners();
//     final response = await http.get(
//       Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books/$bookId/chapters'),
//       headers: {'api-key': apiKey},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       List<dynamic> chapters = data['data'];
//       chapters = chapters.where((chapter) => chapter['number'] != 'intro').toList();
//       _chapters[bookId] = chapters;
//       notifyListeners();
//     } else {
//       throw Exception('Failed to load chapters');
//     }
//     isLoadingChapters = false;
//     notifyListeners();
//   }
//
//   List<dynamic>? getChapters(String bookId) {
//     return _chapters[bookId];
//   }
//
//
//
// }
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BibleProvider with ChangeNotifier {
  final String apiKey = dotenv.env['BIBLE_KEY'] ?? '';
  List<dynamic> _translations = [];
  List<dynamic> _books = [];
  List<dynamic> _filteredBooks = [];
  Map<String, List<dynamic>> _chapters = {};
  bool isLoadingBooks = false;
  bool isLoadingChapters = false;

  List<dynamic> get translations => _translations;
  List<dynamic> get books => _books;
  List<dynamic> get filteredBooks => _filteredBooks.isNotEmpty ? _filteredBooks : _books;
  Map<String, List<dynamic>> get chapters => _chapters;

  Future<void> fetchTranslations() async {
    final response = await http.get(
      Uri.parse('https://api.scripture.api.bible/v1/bibles'),
      headers: {'api-key': apiKey},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _translations = data['data'];
      notifyListeners();
    } else {
      throw Exception('Failed to load translations');
    }
  }

  Future<void> fetchBooks(String translationId) async {
    isLoadingBooks = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books'),
        headers: {'api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _books = data['data'];
        _filteredBooks = _books; // Initialize filtered books with all books
        print("Books fetched successfully: ${_books.length} books found.");
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print("Error fetching books: $e");
    } finally {
      isLoadingBooks = false;
      notifyListeners();
    }
  }

  Future<void> fetchChapters(String translationId, String bookId) async {
    isLoadingChapters = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('https://api.scripture.api.bible/v1/bibles/$translationId/books/$bookId/chapters'),
        headers: {'api-key': apiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> chapters = data['data'];
        chapters = chapters.where((chapter) => chapter['number'] != 'intro').toList();
        _chapters[bookId] = chapters;
        print("Chapters for book $bookId fetched successfully: ${chapters.length} chapters found.");
      } else {
        throw Exception('Failed to load chapters');
      }
    } catch (e) {
      print("Error fetching chapters: $e");
    } finally {
      isLoadingChapters = false;
      notifyListeners();
    }
  }

  List<dynamic>? getChapters(String bookId) {
    return _chapters[bookId];
  }

  void filterBooks(String query) {
    if (query.isEmpty) {
      _filteredBooks = _books;
    } else {
      _filteredBooks = _books.where((book) {
        return book['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }
}

