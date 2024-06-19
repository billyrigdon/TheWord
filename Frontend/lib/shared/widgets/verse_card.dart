
import 'dart:async';
import 'package:flutter/material.dart';

class VerseCard extends StatefulWidget {
  final String verseId;
  final String verseContent;
  final String note;
  final int likesCount;
  final int commentCount;
  final String? username;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isSaved;
  final bool isPublished; // New property
  final ValueChanged<String> onSaveNote;
  final VoidCallback? onPublish; // Optional publish function
  final VoidCallback? onUnpublish; // Optional unpublish function

  VerseCard({
    required this.verseId,
    required this.note,
    required this.verseContent,
    required this.likesCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.isSaved,
    required this.isPublished, // Initialize new property
    required this.onSaveNote,
    this.username,
    this.onPublish,
    this.onUnpublish,
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
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSaveNote.call(note);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.brightness == Brightness.light
        ? theme.cardColor.withOpacity(0.9)
        : theme.cardColor.withOpacity(0.7);

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: backgroundColor,
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.isSaved ? _toggleExpand : widget.onComment,
            child: ListTile(
              title: Text(widget.verseId),
              subtitle: Text(
                widget.verseContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: widget.isSaved
                  ? IconButton(
                      icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: _toggleExpand,
                    )
                  : null,
            ),
          ),
          if (!_isExpanded && !widget.isSaved)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(widget.note),
                ],
              ),
            ),
          if (_isExpanded && widget.isSaved)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Right-align the button
                children: [
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Add a note here!',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onSaveNote(_noteController.text);
                        },
                        child: const Text('Save Note'),
                      ),
                      const SizedBox(width: 12.0),
                      if (widget.isPublished && widget.onUnpublish != null)
                        ElevatedButton(
                          onPressed: widget.onUnpublish,
                          child: const Text('Unpublish'),
                        )
                      else if (!widget.isPublished && widget.onPublish != null)
                        ElevatedButton(
                          onPressed: widget.onPublish,
                          child: const Text('Publish'),
                        ),
                    ],
                  )
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0, left: 18.0),
            child: Row(
              mainAxisAlignment: !widget.isSaved
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (!widget.isSaved) Text('${widget.username!}'),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (!widget.isSaved) Text(widget.likesCount.toString()),
                  if (!widget.isSaved)
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      onPressed: widget.onLike,
                    ),
                  Text(widget.commentCount.toString()),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: widget.onComment,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
