import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: friendProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: friendProvider.friendRequests.length,
        itemBuilder: (context, index) {
          final request = friendProvider.friendRequests[index];
          return ListTile(
            title: Text(request.username),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await friendProvider.respondFriendRequest(request.userID, accept: true);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await friendProvider.respondFriendRequest(request.userID, accept: false);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
