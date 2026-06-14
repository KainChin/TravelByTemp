import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth        = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  /// Stream lắng nghe trạng thái đăng nhập (null = chưa đăng nhập)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại
  static User? get currentUser => _auth.currentUser;

  /// Đăng nhập bằng Google
  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user huỷ

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  /// Đăng xuất
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}