import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/event/data/event_model.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of all upcoming events
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Create an event
  Future<void> createEvent({
    required String title,
    required String description,
    required String organizerId,
    required DateTime dateTime,
    String location = '',
    double? latitude,
    double? longitude,
  }) async {
    try {
      final docRef = _firestore.collection('events').doc();
      final event = EventModel(
        id: docRef.id,
        title: title,
        description: description,
        organizerId: organizerId,
        dateTime: dateTime,
        location: location,
        latitude: latitude,
        longitude: longitude,
        attendeeUids: [organizerId], // Organizer is automatically attending
      );

      await docRef.set(event.toJson());
    } catch (e) {
      throw AppException(
        title: 'Event Creation Failed',
        message: 'Failed to create event. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // RSVP to an event
  Future<void> rsvpToEvent(String eventId, String uid) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendeeUids': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw AppException(
        title: 'RSVP Failed',
        message: 'Failed to RSVP to event. Please check your connection.',
        actionText: 'Retry',
      );
    }
  }

  // Cancel RSVP
  Future<void> cancelRsvp(String eventId, String uid) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendeeUids': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      throw AppException(
        title: 'Action Failed',
        message: 'Failed to cancel RSVP. Please try again.',
        actionText: 'Retry',
      );
    }
  }
}
