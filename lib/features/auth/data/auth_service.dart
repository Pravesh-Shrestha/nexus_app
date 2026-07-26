import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nexus_app/core/utils/firestore_cache_extension.dart';
import 'package:nexus_app/features/auth/data/user_model.dart';
import 'package:nexus_app/features/auth/data/user_settings_model.dart';
import 'package:nexus_app/core/exceptions/app_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with Email & Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError('Sign Up Failed', e);
    } catch (e) {
      throw AppException(
        title: 'Sign Up Failed',
        message: 'An unexpected error occurred. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Login with Email & Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError('Login Failed', e);
    } catch (e) {
      throw AppException(
        title: 'Login Failed',
        message: 'An unexpected error occurred. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError('Google Sign-In Failed', e);
    } catch (e) {
      throw AppException(
        title: 'Google Sign-In Failed',
        message: 'An error occurred during Google Sign-In. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Save User Data to Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw AppException(
        title: 'Profile Save Failed',
        message: 'Failed to save profile. Please check your internet connection and try again.',
        actionText: 'Retry',
      );
    }
  }

  // Get User Data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).getCacheFirst();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw AppException(
        title: 'Profile Load Failed',
        message: 'Failed to load profile. Please pull down to refresh or check your internet connection.',
        actionText: 'Retry',
      );
    }
  }

  // Get User Settings from the separate 'settings' collection
  Future<UserSettingsModel> getUserSettings(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserSettingsModel.fromJson(doc.data()!);
      }
      return UserSettingsModel(uid: uid); // Default settings
    } catch (e) {
      return UserSettingsModel(uid: uid);
    }
  }

  // Update User Settings in collection 'settings'
  Future<void> updateUserSettings(UserSettingsModel settings) async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(settings.uid)
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw AppException(
        title: 'Settings Update Failed',
        message: 'Failed to update user settings. Please try again.',
        actionText: 'Retry',
      );
    }
  }

  // Update Password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'No authenticated user found.';
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AppException(
          title: 'Update Password Failed',
          message: 'The current password you entered is incorrect.',
          actionText: 'Try Again',
        );
      }
      throw _handleFirebaseError('Update Password Failed', e);
    } catch (e) {
      throw AppException(
        title: 'Update Password Failed',
        message: 'An error occurred while updating the password.',
        actionText: 'Retry',
      );
    }
  }

  // Helper method to map Firebase errors to human-readable strings
  AppException _handleFirebaseError(String title, FirebaseAuthException e) {
    String message;
    String actionText = 'Try Again';
    
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        message = 'Invalid email or password.';
        actionText = 'Check Credentials';
        break;
      case 'email-already-in-use':
        message = 'An account already exists for that email.';
        actionText = 'Go to Login';
        break;
      case 'weak-password':
        message = 'Please enter a stronger password.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        actionText = 'Check Connection';
        break;
      default:
        message = e.message ?? 'Authentication failed. Please try again.';
        break;
    }
    
    return AppException(
      title: title,
      message: message,
      actionText: actionText,
    );
  }
}
