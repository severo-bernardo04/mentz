import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/models/app_user.dart';
import 'package:mentz/services/user_profile_service.dart';

/// Usuário mínimo do Firebase Auth, só com o que o perfil usa.
class _FakeUser implements User {
  @override
  final String uid;
  @override
  String? get email => 'aluno@mentz.app';
  @override
  String? get displayName => null;

  _FakeUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = UserProfileService(firestore: firestore);
  });

  test('o cadastro grava a versão e a data do aceite dos termos', () async {
    await service.createIfMissing(
      _FakeUser('u1'),
      name: 'Aluno',
      termsVersion: '1.0',
    );

    final data = (await firestore.doc('users/u1').get()).data()!;
    final terms = data['termsAcceptance'] as Map<String, dynamic>;
    expect(terms['version'], '1.0');
    expect(terms['acceptedAt'], isNotNull);

    final user = AppUser.fromMap('u1', data);
    expect(user.termsVersion, '1.0');
    expect(user.termsAcceptedAt, isNotNull);
  });

  test('sem informar a versão, nenhum aceite é registrado', () async {
    await service.createIfMissing(_FakeUser('u2'), name: 'Aluno');

    final data = (await firestore.doc('users/u2').get()).data()!;
    expect(data.containsKey('termsAcceptance'), isFalse);
  });

  test('conta antiga, sem aceite, continua sendo lida normalmente', () {
    final user = AppUser.fromMap('old', {
      'name': 'Antigo',
      'email': 'a@a.com',
      'role': 'student',
    });
    expect(user.termsVersion, isNull);
    expect(user.termsAcceptedAt, isNull);
  });

  test('não sobrescreve o aceite de um perfil que já existe', () async {
    await service.createIfMissing(_FakeUser('u3'), termsVersion: '1.0');
    await service.createIfMissing(_FakeUser('u3'), termsVersion: '2.0');

    final data = (await firestore.doc('users/u3').get()).data()!;
    expect((data['termsAcceptance'] as Map)['version'], '1.0');
  });
}
