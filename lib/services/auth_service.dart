import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void> init(String serverClientId) {
    return _googleSignIn.initialize(serverClientId: serverClientId);
  }

  Stream<User?> get userChanges => _auth.userChanges();

  Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.authenticate();
      final authentication = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken,
      );
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
  }
}
