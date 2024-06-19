import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FriendProvider with ChangeNotifier {
  List<dynamic> friends = [];
  List<dynamic> suggestedFriends = [];
  List<Friend> friendRequests = [];
  List<int> sentFriendRequests = [];
  bool isLoading = true;

  reset() {
    friends = [];
    suggestedFriends = [];
    friendRequests = [];
    sentFriendRequests = [];
  }

  Future<void> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoading = true;
    notifyListeners();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/friends'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      if (responseBody != null) {
        friends = (responseBody as List<dynamic>)
            .map<Friend>((data) => Friend.fromJson(data))
            .toList();
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSuggestedFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoading = true;
    notifyListeners();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/friends/suggested'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      if (responseBody != null) {
        suggestedFriends = (responseBody as List<dynamic>)
            .map<Friend>((data) => Friend.fromJson(data))
            .toList();
      }
    }
    isLoading = false;
    notifyListeners();
  }


  Future<void> fetchFriendRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoading = true;
    notifyListeners();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/friends/requests'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      friendRequests = responseBody != null ?   (responseBody as List<dynamic>)
            .map<Friend>((data) => Friend.fromJson(data))
            .toList() : [];

    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> sendFriendRequest(int friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/friends/$friendId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      sentFriendRequests.add(friendId);
      notifyListeners();
      return true;
    } else {
      await fetchFriendRequests();
      await fetchSuggestedFriends();
      notifyListeners();
    }
    return false;
  }

  Future<void> removeFriend(int friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/friends/$friendId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      friends.removeWhere((friend) => friend.userID == friendId);
      await fetchFriends();
      await fetchSuggestedFriends();
      notifyListeners();
    }
  }

  Future<void> respondFriendRequest(int userId, {required bool accept}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/friends/requests/$userId/respond'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'accept': accept}),
    );
    if (response.statusCode == 200) {
      await fetchFriendRequests();
      await fetchFriends();
      notifyListeners();
    }
  }

  bool isFriendRequested(int friendId) {
    return sentFriendRequests.contains(friendId);
  }
}

class Friend {
  final int userID;
  final String username;
  final int mutualFriends;
  final int totalLikeCount;

  Friend({
    required this.userID,
    required this.username,
    required this.mutualFriends,
    required this.totalLikeCount,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userID: json['user_id'],
      username: json['username'],
      mutualFriends: json['mutual_friends'] ?? 0,
      totalLikeCount: json['total_like_count'] ?? 0,
    );
  }
}



