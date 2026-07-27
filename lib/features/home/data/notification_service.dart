import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/features/home/data/notification_model.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';
import 'package:nexus_app/core/services/push_notification_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch notifications for a user (non-expired, max 20, descending order)
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('expireAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expireAt') // Note: if we order by expireAt we can do it, but ordering by createdAt is standard.
          // Firestore requires composite index if we do where & orderBy on different fields. 
          // Let's order by createdAt descending on client side, or just query without filters and filter/sort on client side to avoid index creation errors.
          .limit(40) // Limit to avoid large reads
          .get();

      final list = querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data()))
          .toList();

      // Sort by createdAt descending on client side to avoid requiring composite indexes
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      // In case indexing fails or not set up yet, fallback to a simpler query without where filter
      try {
        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .limit(40)
            .get();
        final list = querySnapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .where((n) => n.expireAt.isAfter(DateTime.now()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (ex) {
        throw AppException(
          title: 'Load Failed',
          message: 'Failed to load notifications. Please check your internet connection.',
          actionText: 'Retry',
        );
      }
    }
  }

  // Send a notification to another user's subcollection
  Future<void> sendNotification(String receiverId, NotificationModel notification) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc(notification.id.isNotEmpty ? notification.id : null);
      
      final finalNotification = notification.id.isEmpty 
          ? notification.copyWith(id: docRef.id)
          : notification;

      await docRef.set(finalNotification.toJson());

      // Trigger client-side push notification
      try {
        await PushNotificationService.sendPushToUser(
          recipientId: receiverId,
          title: finalNotification.type == 'friend_request' 
              ? 'New Friend Request'
              : 'Nexus Alert',
          body: finalNotification.title,
          type: finalNotification.type,
          extraData: finalNotification.relatedId != null && finalNotification.relatedId!.isNotEmpty 
              ? {'relatedId': finalNotification.relatedId!} 
              : null,
        );
      } catch (e) {
        debugPrint('Client-side Push Notification trigger failed: $e');
      }
    } catch (e) {
      throw AppException(
        title: 'Action Failed',
        message: 'Failed to send notification. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw AppException(
        title: 'Action Failed',
        message: 'Failed to mark notifications as read.',
        actionText: 'Retry',
      );
    }
  }

  // Update status (e.g. pending/accepted/declined) of a notification
  Future<void> updateNotificationStatus(String userId, String notificationId, String status) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': status,
            'isRead': true,
          });
    } catch (e) {
      throw AppException(
        title: 'Action Failed',
        message: 'Failed to update notification status.',
        actionText: 'Retry',
      );
    }
  }

  // Delete a specific notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw AppException(
        title: 'Action Failed',
        message: 'Failed to delete notification.',
        actionText: 'Retry',
      );
    }
  }
}
