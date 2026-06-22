class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String dob;
  final String gender;
  
  // INB1 Setup Data
  final String role; // Gamer, Streamer, Creator, Others
  final List<String> favoriteGames; // FreeFire, Valorant, PUBG, Others
  final String playstyle; // Casual, Crazy, Hardcore, Others
  final String skillLevel; // Noob, Soso, Pro, E-Player
  
  // Image URL from Cloudinary (for future)
  final String profileImageUrl;

  // New Fields
  final String bio;
  final String phoneNumber;
  final String location;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    required this.dob,
    required this.gender,
    this.role = '',
    this.favoriteGames = const [],
    this.playstyle = '',
    this.skillLevel = '',
    this.profileImageUrl = '',
    this.bio = '',
    this.phoneNumber = '',
    this.location = '',
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'username': username,
      'dob': dob,
      'gender': gender,
      'role': role,
      'favoriteGames': favoriteGames,
      'playstyle': playstyle,
      'skillLevel': skillLevel,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'location': location,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Firestore Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      favoriteGames: List<String>.from(json['favoriteGames'] ?? []),
      playstyle: json['playstyle'] ?? '',
      skillLevel: json['skillLevel'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      location: json['location'] ?? '',
    );
  }

  // Create a copy of UserModel with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? dob,
    String? gender,
    String? role,
    List<String>? favoriteGames,
    String? playstyle,
    String? skillLevel,
    String? profileImageUrl,
    String? bio,
    String? phoneNumber,
    String? location,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      favoriteGames: favoriteGames ?? this.favoriteGames,
      playstyle: playstyle ?? this.playstyle,
      skillLevel: skillLevel ?? this.skillLevel,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
    );
  }
}
