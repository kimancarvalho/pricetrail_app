import '../models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Stream<AppUser?> getUser(String userId) {
    final docRef = _db.collection('users').doc(userId);

    return docRef.snapshots().asyncMap((doc) async {
      // Se não existir cria automaticamente
      if (!doc.exists) {
        final authUser = FirebaseAuth.instance.currentUser;

        await docRef.set({
          'email': authUser?.email ?? '',
          'name': authUser?.displayName ?? 'User',
          'location': '',
          'transport': '',
          'lifetimeSavings': 0,
          'monthlySavings': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // depois volta a buscar
        final newDoc = await docRef.get();
        return AppUser.fromFirestore(newDoc.data()!);
      }

      return AppUser.fromFirestore(doc.data()!);
    });
  }
}
