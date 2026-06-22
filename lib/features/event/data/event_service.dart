import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/event/data/event_model.dart';

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
        attendeeUids: [organizerId], // Organizer is automatically attending
      );

      await docRef.set(event.toJson());
    } catch (e) {
      throw 'Failed to create event: $e';
    }
  }

  // RSVP to an event
  Future<void> rsvpToEvent(String eventId, String uid) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendeeUids': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw 'Failed to RSVP to event: $e';
    }
  }

  // Cancel RSVP
  Future<void> cancelRsvp(String eventId, String uid) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendeeUids': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      throw 'Failed to cancel RSVP: $e';
    }
  }
}
