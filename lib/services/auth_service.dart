import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail(String email, String password, String username) async {
    try {
      if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(username)) {
        throw Exception('Username must be lowercase and cannot contain spaces or special characters.');
      }

      var existing = await _db.collection('users').where('username', isEqualTo: username).get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Username is already taken!');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'xp_score': 0,
          'rank': 'Beginner Tracker',
          'friends': [],
          'profileUrl': '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'^\[.*?\]\s*'), '').replaceAll('Exception: ', ''));
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception('Invalid email or password.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}