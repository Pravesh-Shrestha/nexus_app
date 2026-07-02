import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final DateTime dateTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> attendeeUids;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.dateTime,
    this.location = '',
    this.latitude,
    this.longitude,
    this.attendeeUids = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'attendeeUids': attendeeUids,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final Timestamp ts = json['dateTime'] as Timestamp? ?? Timestamp.now();
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      organizerId: json['organizerId'] ?? '',
      dateTime: ts.toDate(),
      location: json['location'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      attendeeUids: List<String>.from(json['attendeeUids'] ?? []),
    );
  }
}
