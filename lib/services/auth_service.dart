import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? AppUser.fromSnapshot(snap) : null;
  }

  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final profile = await getProfile(cred.user!.uid);
    if (profile == null) {
      await _auth.signOut();
      throw StateError('No user profile exists for this account.');
    }
    return profile;
  }

  Future<void> signOut() => _auth.signOut();
}
