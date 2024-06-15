class Friend {
  final int id;
  final int userId;
  final int friendId;
  final String status;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: json['status'],
    );
  }
}