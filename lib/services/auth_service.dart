import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // This connects to Firebase's authentication system
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Attempts to sign in a user with email and password.
  // Returns null if successful, or an error message (String) if it fails.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // null means "no error, everything worked"
    } on FirebaseAuthException catch (e) {
      // Firebase gives us specific error codes - we turn them into
      // friendly messages a normal person can understand
      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        return 'Please enter a valid email address.';
      } else if (e.code == 'invalid-credential') {
        return 'Incorrect email or password.';
      } else {
        return 'Login failed: ${e.message}';
      }
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
  
  // Creates a new user account in Firebase Authentication,
  // then saves their extra details (name, role, department, etc.) in Firestore.
  Future<String?> signUp({
    required String fullName,
    required String staffId,
    required String department,
    required String designation,
    required String email,
    required String mobile,
    required String password,
    required String role, // 'teacher' or 'admin'
  }) async {
    try {
      // Step A: Create the login credentials in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Step B: Save the extra profile details in Firestore,
      // using the new user's unique ID (uid) as the document name
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'fullName': fullName,
        'staffId': staffId,
        'department': department,
        'designation': designation,
        'email': email.trim(),
        'mobile': mobile,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // no error, success!
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'An account already exists with this email.';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        return 'Please enter a valid email address.';
      } else {
        return 'Registration failed: ${e.message}';
      }
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
  // Looks up a user's role ("teacher" or "admin") from their Firestore profile.
  // Returns null if we can't find it for some reason.
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Signs the current user out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}