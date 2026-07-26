class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String imageUrl;
  final List<String> memberUids;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    this.imageUrl = '',
    this.memberUids = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'imageUrl': imageUrl,
      'memberUids': memberUids,
    };
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      memberUids: List<String>.from(json['memberUids'] ?? []),
    );
  }
}
