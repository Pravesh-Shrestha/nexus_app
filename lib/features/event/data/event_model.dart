import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final DateTime dateTime;
  final String location;
  final List<String> attendeeUids;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.dateTime,
    this.location = '',
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
      attendeeUids: List<String>.from(json['attendeeUids'] ?? []),
    );
  }
}
