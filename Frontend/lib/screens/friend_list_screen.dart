// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/friend_provider.dart';
// import '../providers/settings_provider.dart';
//
// class FriendListScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final friendProvider = Provider.of<FriendProvider>(context);
//     final settingsProvider = Provider.of<SettingsProvider>(context);
//
//     return Scaffold(
//       body: friendProvider.isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           Container(
//             height: 150,
//             child: PageView.builder(
//               itemCount: friendProvider.suggestedFriends.length,
//               controller: PageController(viewportFraction: 0.8),
//               itemBuilder: (context, index) {
//                 final suggestedFriend = friendProvider.suggestedFriends[index];
//                 return Card(
//                   color: settingsProvider.currentColor,
//                   margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
//                   elevation: 5,
//                   child: Padding(
//                     padding: const EdgeInsets.all(10.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Row(
//                           children: [
//                             Text(
//                               suggestedFriend.username,
//                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                               textAlign: TextAlign.left,
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 10),
//                         ElevatedButton(
//                           onPressed: () async {
//                             final success = await friendProvider.sendFriendRequest(suggestedFriend.userID);
//                             if (success) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text('Friend request sent to ${suggestedFriend.username}')),
//                               );
//                             }
//                           },
//                           child: Text(
//                               ? 'Requested'
//                               : 'Add Friend'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Divider(height: 20, color: Colors.black),
//           const Text('Friends', style: TextStyle(fontSize: 18.0)),
//           // Your Friends List
//           Expanded(
//             child: ListView.builder(
//               itemCount: friendProvider.friends.length,
//               itemBuilder: (context, index) {
//                 final friend = friendProvider.friends[index];
//                 return ListTile(
//                   title: Text(friend.username, textAlign: TextAlign.left),
//                   trailing: IconButton(
//                     icon: Icon(Icons.remove_circle, color: Colors.red),
//                     onPressed: () {
//                       friendProvider.removeFriend(friend.userID);
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/friend_provider.dart';
import '../providers/settings_provider.dart';

class FriendListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: friendProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Suggested Users',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          friendProvider.suggestedFriends.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No suggested friends at the moment.',
              style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
              textAlign: TextAlign.left,
            ),
          )
              : Container(
            height: 180,
            child: PageView.builder(
              itemCount: friendProvider.suggestedFriends.length,
              controller: PageController(viewportFraction: 0.8),
              itemBuilder: (context, index) {
                final suggestedFriend = friendProvider.suggestedFriends[index];
                return Card(
                  color: settingsProvider.currentColor,
                  margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  elevation: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          suggestedFriend.username,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: settingsProvider.getFontColor(settingsProvider.currentColor!),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final success = await friendProvider.sendFriendRequest(suggestedFriend.userID);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Friend request sent to ${suggestedFriend.username}')),
                              );
                            }
                          },
                          child: Text(
                            friendProvider.isFriendRequested(suggestedFriend.userID)
                                ? 'Friend Request Sent'
                                : 'Add Friend',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 20, color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Friends',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          friendProvider.friends.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'You have no friends added yet.',
              style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic),
              textAlign: TextAlign.left,
            ),
          )
              : Container(
            height: 180,
            child: PageView.builder(
              itemCount: friendProvider.friends.length,
              controller: PageController(viewportFraction: 0.8),
              itemBuilder: (context, index) {
                final friend = friendProvider.friends[index];
                return Card(
                  color: settingsProvider.currentColor,
                  margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  elevation: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          friend.username,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: settingsProvider.getFontColor(settingsProvider.currentColor!),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await friendProvider.removeFriend(friend.userID);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${friend.username} has been removed from your friends')),
                            );
                          },
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: settingsProvider.getFontColor(settingsProvider.currentColor!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


