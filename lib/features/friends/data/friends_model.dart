class FriendsModel {
  final String uid;
  final List<String> friendUids;

  FriendsModel({
    required this.uid,
    this.friendUids = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'friendUids': friendUids,
    };
  }

  factory FriendsModel.fromJson(Map<String, dynamic> json) {
    return FriendsModel(
      uid: json['uid'] ?? '',
      friendUids: List<String>.from(json['friendUids'] ?? []),
    );
  }
}
