import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/friend.dart';

class FriendProvider with ChangeNotifier {
  List<dynamic> friends = [];
  List<dynamic> suggestedFriends = [];

  bool isLoading = true;

  reset() {
    friends = [];
    suggestedFriends = [];

  }

  Future<void> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoading = true;
    notifyListeners();

    final response = await http.get(
      Uri.parse('http://billyrigdon.dev:8110/friends'),
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
    print('fetching suggestions');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoading = true;
    notifyListeners();

    final response = await http.get(
      Uri.parse('http://billyrigdon.dev:8110/friends/suggested'),
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

  Future<void> removeFriend(int friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.delete(
      Uri.parse('http://billyrigdon.dev:8110/friends/$friendId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      friends.removeWhere((friend) => friend.userID == friendId);
      await fetchFriends();
      await fetchSuggestedFriends();
      notifyListeners();
    }
  }


}





