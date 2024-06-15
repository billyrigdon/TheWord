// // import 'dart:async';
// // import 'package:flutter/material.dart';
// //
// // class VerseCard extends StatefulWidget {
// //   final String verseId;
// //   final String note;
// //   final int likesCount;
// //   final VoidCallback? onLike;
// //   final VoidCallback onComment;
// //   final bool isSaved;
// //   final ValueChanged<String> onSaveNote;
// //
// //   VerseCard({
// //     required this.verseId,
// //     required this.note,
// //     required this.likesCount,
// //     this.onLike,
// //     required this.onComment,
// //     required this.isSaved,
// //     required this.onSaveNote,
// //   });
// //
// //   @override
// //   _VerseCardState createState() => _VerseCardState();
// // }
// //
// // class _VerseCardState extends State<VerseCard> {
// //   bool _isExpanded = false;
// //   TextEditingController _noteController = TextEditingController();
// //   Timer? _debounce;
// //
// //   @override
// //   void initState() {
// //     _noteController.text = widget.note;
// //     super.initState();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _noteController.dispose();
// //     _debounce?.cancel();
// //     super.dispose();
// //   }
// //
// //   void _toggleExpand() {
// //     setState(() {
// //       _isExpanded = !_isExpanded;
// //     });
// //   }
// //
// //   void _onNoteChanged(String note) {
// //     if (_debounce?.isActive ?? false) _debounce?.cancel();
// //
// //     _debounce = Timer(const Duration(milliseconds: 300), () {
// //       widget.onSaveNote.call(note);
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     final backgroundColor = theme.brightness == Brightness.light
// //         ? theme.cardColor.withOpacity(0.9)
// //         : theme.cardColor.withOpacity(0.7);
// //
// //     return Card(
// //       margin: EdgeInsets.all(8.0),
// //       color: backgroundColor,
// //       child: Column(
// //         children: [
// //           ListTile(
// //             title: Text(widget.verseId),
// //             subtitle: Text(
// //               widget.note,
// //               maxLines: 2,
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //             trailing: widget.isSaved
// //                 ? IconButton(
// //               icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
// //               onPressed: _toggleExpand,
// //             )
// //                 : null,
// //           ),
// //           if (_isExpanded && widget.isSaved)
// //             Padding(
// //               padding: const EdgeInsets.all(8.0),
// //               child: Column(
// //                 children: [
// //                   TextField(
// //                     controller: _noteController,
// //                     onChanged: _onNoteChanged,
// //                     decoration: const InputDecoration(
// //                       alignLabelWithHint: true,
// //                       labelText: 'Add a note here!',
// //                       border: OutlineInputBorder(),
// //                     ),
// //                     maxLines: 8,
// //                   ),
// //                   const SizedBox(height: 8.0),
// //                 ],
// //               ),
// //             ),
// //           Padding(
// //             padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.end,
// //               children: [
// //                 if (widget.onLike != null)
// //                   Text(widget.likesCount.toString()),
// //                 if (widget.onLike != null)
// //                   IconButton(
// //                     icon: Icon(Icons.thumb_up),
// //                     onPressed: widget.onLike,
// //                   ),
// //                 IconButton(
// //                   icon: Icon(Icons.comment),
// //                   onPressed: widget.onComment,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'dart:async';
// import 'package:flutter/material.dart';
//
// class VerseCard extends StatefulWidget {
//   final String verseId;
//   final String note;
//   final int likesCount;
//   final int commentCount; // Added comment count
//   final VoidCallback onLike;
//   final VoidCallback onComment;
//   final bool isSaved;
//   final ValueChanged<String> onSaveNote;
//
//   VerseCard({
//     required this.verseId,
//     required this.note,
//     required this.likesCount,
//     required this.commentCount, // Added comment count
//     required this.onLike,
//     required this.onComment,
//     required this.isSaved,
//     required this.onSaveNote,
//   });
//
//   @override
//   _VerseCardState createState() => _VerseCardState();
// }
//
// class _VerseCardState extends State<VerseCard> {
//   bool _isExpanded = false;
//   TextEditingController _noteController = TextEditingController();
//   Timer? _debounce;
//
//   @override
//   void initState() {
//     _noteController.text = widget.note;
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     _noteController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }
//
//   void _toggleExpand() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//     });
//   }
//
//   void _onNoteChanged(String note) {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       widget.onSaveNote.call(note);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final backgroundColor = theme.brightness == Brightness.light
//         ? theme.cardColor.withOpacity(0.9)
//         : theme.cardColor.withOpacity(0.7);
//
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       color: backgroundColor,
//       child: Column(
//         children: [
//           ListTile(
//             title: Text(widget.verseId),
//             subtitle: Text(
//               widget.note,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             trailing: widget.isSaved
//                 ? IconButton(
//               icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
//               onPressed: _toggleExpand,
//             )
//                 : null,
//           ),
//           if (_isExpanded && widget.isSaved)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _noteController,
//                     onChanged: _onNoteChanged,
//                     decoration: const InputDecoration(
//                       alignLabelWithHint: true,
//                       labelText: 'Add a note here!',
//                       border: OutlineInputBorder(),
//                     ),
//                     maxLines: 8,
//                   ),
//                   const SizedBox(height: 8.0),
//                 ],
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text(widget.likesCount.toString()),
//                 IconButton(
//                   icon: Icon(Icons.thumb_up),
//                   onPressed: widget.onLike,
//                 ),
//                 Text(widget.commentCount.toString()), // Display comment count
//                 IconButton(
//                   icon: Icon(Icons.comment),
//                   onPressed: widget.onComment,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//


// verse_card.dart

// verse_card.dart

import 'dart:async';
import 'package:flutter/material.dart';

class VerseCard extends StatefulWidget {
  final String verseId;
  final String note;
  final int likesCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final bool isSaved;
  final ValueChanged<String> onSaveNote;

  VerseCard({
    required this.verseId,
    required this.note,
    required this.likesCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.isSaved,
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
      margin: EdgeInsets.all(8.0),
      color: backgroundColor,
      child: Column(
        children: [
          ListTile(
            title: Text(widget.verseId),
            subtitle: Text(
              widget.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: widget.isSaved
                ? IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpand,
            )
                : null,
          ),
          if (_isExpanded && widget.isSaved)
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.likesCount.toString()),
                IconButton(
                  icon: Icon(Icons.thumb_up),
                  onPressed: widget.onLike,
                ),
                Text(widget.commentCount.toString()),
                IconButton(
                  icon: Icon(Icons.comment),
                  onPressed: widget.onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
