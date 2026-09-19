import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/firestore_service.dart';
import '../models/app_user.dart';
import 'app_providers.dart';

enum AuthStatus { unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({required this.status, this.user});

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  final FirestoreService _firestore = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  AuthState build() {
    fb.FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  void _onAuthStateChanged(fb.User? firebaseUser) {
    if (firebaseUser == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    _loadUser(firebaseUser);
  }

  Future<void> _loadUser(fb.User firebaseUser) async {
    final appUser = await _firestore.getUser(firebaseUser.uid);
    if (appUser != null) {
      state = AuthState(status: AuthStatus.authenticated, user: appUser);
      return;
    }
    final newUser = _mapFirebaseUser(firebaseUser);
    await _firestore.saveUser(newUser);
    await ref.read(localStoreProvider).saveUser(newUser);
    state = AuthState(status: AuthStatus.authenticated, user: newUser);
  }

  AppUser _mapFirebaseUser(fb.User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'EcoWell User',
      email: firebaseUser.email ?? '',
      age: 0,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      avatarUrl: firebaseUser.photoURL,
      handle: '@${(firebaseUser.email?.split('@').first ?? 'user')}',
      bio: 'Nature enthusiast & mindfulness practitioner 🌿',
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required int age,
    required String password,
  }) async {
    final credential = await fb.FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.reload();

    final user = AppUser(
      id: credential.user!.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      age: age,
      createdAt: DateTime.now(),
      handle: '@${email.trim().split('@').first}',
      bio: 'Nature enthusiast & mindfulness practitioner 🌿',
    );
    await _firestore.saveUser(user);
    await ref.read(localStoreProvider).saveUser(user);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> login({required String email, required String password}) async {
    await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await fb.FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await fb.FirebaseAuth.instance.signOut();
    await ref.read(localStoreProvider).clearUser();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
