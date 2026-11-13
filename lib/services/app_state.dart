import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/models.dart';
import 'firestore_service.dart';

/// Holds the signed-in user and their profile.
class AppState extends ChangeNotifier {
  AppState(this._fs) {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirestoreService _fs;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? firebaseUser;
  AppUser? profile;
  bool initializing = true;
  bool profileChecked = false;
  bool registering = false;

  void _onAuthChanged(User? user) {
    firebaseUser = user;
    _profileSub?.cancel();
    profile = null;
    profileChecked = false;
    initializing = false;

    if (user != null) {
      _profileSub = _fs.userStream(user.uid).listen((p) {
        profile = p;
        profileChecked = true;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    registering = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _fs.createUser(AppUser(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
      ));
    } finally {
      registering = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> setAvailability(bool value) async {
    final p = profile;
    if (p == null) return;
    await _fs.setAvailability(p.uid, value);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
