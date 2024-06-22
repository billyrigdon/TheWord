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