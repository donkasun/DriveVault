import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  final Stream<User?>? _testAuthStateChanges;
  final User? _testCurrentUser;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    Stream<User?>? testAuthStateChanges,
    User? testCurrentUser,
  })  : _firebaseAuth = testAuthStateChanges != null || testCurrentUser != null
            ? null
            : (firebaseAuth ?? FirebaseAuth.instance),
        _googleSignIn = testAuthStateChanges != null || testCurrentUser != null
            ? null
            : (googleSignIn ?? GoogleSignIn()),
        _testAuthStateChanges = testAuthStateChanges,
        _testCurrentUser = testCurrentUser;

  /// In-memory auth state for unit tests (avoids Firebase initialization).
  factory AuthRepository.testing({
    User? currentUser,
    Stream<User?>? authStateChanges,
  }) {
    return AuthRepository(
      testCurrentUser: currentUser,
      testAuthStateChanges: authStateChanges ?? Stream.value(currentUser),
    );
  }

  Stream<User?> get authStateChanges =>
      _testAuthStateChanges ?? _firebaseAuth!.authStateChanges();

  User? get currentUser => _testCurrentUser ?? _firebaseAuth?.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth!.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      if (_firebaseAuth != null) _firebaseAuth!.signOut(),
      if (_googleSignIn != null) _googleSignIn!.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
