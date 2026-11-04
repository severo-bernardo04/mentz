import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentz/services/user_profile_service.dart';

/// Erro de autenticação com mensagem pronta para mostrar ao usuário.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService({this._auth, UserProfileService? profiles})
      : _profiles = profiles ?? UserProfileService();

  final FirebaseAuth? _auth;
  final UserProfileService _profiles;

  FirebaseAuth get _firebase => _auth ?? FirebaseAuth.instance;

  /// Emite o usuário logado, ou `null` quando não há sessão.
  Stream<User?> get authStateChanges => _firebase.authStateChanges();

  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      final cred = await _firebase.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Garante o perfil de contas criadas antes do Firestore.
      await _profiles.createIfMissing(cred.user!);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final cred = await _firebase.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      await user.updateDisplayName(name.trim());
      await _profiles.createIfMissing(user, name: name);
    });
  }

  Future<void> sendPasswordReset(String email) {
    return _guard(() => _firebase.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _firebase.signOut();

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    } on FirebaseException catch (e) {
      // Erros do Firestore (ex: regras de segurança negando a gravação).
      throw AuthFailure('Não foi possível salvar seu perfil (${e.code}).');
    }
  }

  static String _messageFor(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'E-mail inválido.',
      'user-disabled' => 'Esta conta foi desativada.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
      'E-mail ou senha incorretos.',
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'weak-password' => 'A senha é muito fraca.',
      'too-many-requests' =>
      'Muitas tentativas. Tente novamente em alguns instantes.',
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      _ => 'Não foi possível concluir. Tente novamente.',
    };
  }
}