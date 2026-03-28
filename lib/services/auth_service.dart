import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável por toda a lógica de autenticação.
/// Centralizar aqui isola a dependência do Firebase Auth
/// do resto da app — fácil de testar e de substituir no futuro.
class AuthService {
  AuthService._(); //Não permite ser instanciada

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Utilizador atualmente autenticado — null se não estiver logado
  static User? get currentUser => _auth.currentUser;

  /// Stream que emite sempre que o estado de autenticação muda
  /// (login, logout, token expirado)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Faz login com email e password.
  /// Lança [FirebaseAuthException] em caso de erro.
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Regista um novo utilizador com email e password.
  /// Lança [FirebaseAuthException] em caso de erro.
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Envia email de recuperação de password.
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Termina a sessão do utilizador atual.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Converte os códigos de erro do Firebase em mensagens legíveis
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Incorrect email or password. Try again.';
      case 'wrong-password':
        return 'Incorrect email or password. Try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
