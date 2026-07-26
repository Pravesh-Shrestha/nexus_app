class UserSettingsModel {
  final String uid;
  final bool notificationsEnabled;
  final bool hapticsEnabled;
  final bool proximityEnabled;
  final bool dataSaverEnabled;

  UserSettingsModel({
    required this.uid,
    this.notificationsEnabled = true,
    this.hapticsEnabled = true,
    this.proximityEnabled = true,
    this.dataSaverEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'notificationsEnabled': notificationsEnabled,
      'hapticsEnabled': hapticsEnabled,
      'proximityEnabled': proximityEnabled,
      'dataSaverEnabled': dataSaverEnabled,
    };
  }

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      uid: json['uid'] ?? '',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      hapticsEnabled: json['hapticsEnabled'] ?? true,
      proximityEnabled: json['proximityEnabled'] ?? true,
      dataSaverEnabled: json['dataSaverEnabled'] ?? false,
    );
  }

  UserSettingsModel copyWith({
    String? uid,
    bool? notificationsEnabled,
    bool? hapticsEnabled,
    bool? proximityEnabled,
    bool? dataSaverEnabled,
  }) {
    return UserSettingsModel(
      uid: uid ?? this.uid,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      proximityEnabled: proximityEnabled ?? this.proximityEnabled,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
    );
  }
}
