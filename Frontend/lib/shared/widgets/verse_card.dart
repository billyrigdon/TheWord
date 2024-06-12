import 'dart:async';

import 'package:flutter/material.dart';

class VerseCard extends StatefulWidget {
  final String verseId;
  final String verseText;
  final String note;
  final ValueChanged<String> onSaveNote;

  VerseCard({
    required this.verseId,
    required this.verseText,
    required this.note,
    required this.onSaveNote,
  });

  @override
  _VerseCardState createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> {
  bool _isExpanded = false;
  TextEditingController _noteController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    _noteController.text = widget.note;
    super.initState();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onNoteChanged(String note) {
    // Cancel any existing debounce timer
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    // Start a new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSaveNote.call(note);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.verseId),
            subtitle: Text(widget.verseText),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpand,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _noteController,
                    onChanged: _onNoteChanged,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Add a note here!',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

