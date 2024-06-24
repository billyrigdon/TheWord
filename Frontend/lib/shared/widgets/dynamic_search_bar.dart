import 'package:TheWord/providers/bible_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Define an enum for the different screen types
enum SearchType { BibleBooks, PublicVerses, SavedVerses, Friends, Settings }

class DynamicSearchBar extends StatelessWidget {
  final List<dynamic> data;
  final SearchType searchType;
  final Color? fontColor;

  DynamicSearchBar({
    required this.data,
    required this.searchType,
    this.fontColor,
  });

  _filterMethod(context, filterString) {
    if (searchType == SearchType.BibleBooks) {
      Provider.of<BibleProvider>(context, listen: false).filterBooks(filterString);
    }
  }

  String _getPlaceholderText() {
    switch (searchType) {
      case SearchType.BibleBooks:
        return 'Search Bible books...';
      case SearchType.PublicVerses:
        return 'Search Public Verses...';
      case SearchType.SavedVerses:
        return 'Search Saved Verses...';
      case SearchType.Friends:
        return 'Search Friends...';
      case SearchType.Settings:
        return 'Search Settings...';
      default:
        return 'Search...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: TextField(
          decoration: InputDecoration(
            hintText: _getPlaceholderText(),
            hintStyle: TextStyle(color: fontColor?.withOpacity(0.6)),
            prefixIcon: Icon(Icons.search, color: fontColor),
            filled: true,
            fillColor: fontColor?.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.only(left:8)
          ),
          onChanged: (filterString) {
            _filterMethod(context,filterString);
          },
          style: TextStyle(color: fontColor, fontSize: 16),
        ),
      ),
    );
  }
}
