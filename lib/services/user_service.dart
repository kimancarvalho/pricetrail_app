import '../models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Stream<AppUser?> getUser(String userId) {
    final currentMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return _db.collection('users').doc(userId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) return null;

      // Busca o resumo mensal para o badge do mês
      final summaryDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('summaries')
          .doc(currentMonth)
          .get();

      final monthlySaved = summaryDoc.exists
          ? (summaryDoc.data()?['totalSaved'] ?? 0).toDouble()
          : 0.0;

      final data = doc.data()!;
      return AppUser(
        email: data['email'] ?? '',
        name: data['name'] ?? 'User',
        location: data['location'] ?? '',
        transport: data['transport'] ?? '',
        photoUrl: data['photoUrl'],
        lifetimeSavings: (data['lifetimeSavings'] ?? 0).toDouble(),
        monthlySavings: monthlySaved,
      );
    });
  }
}
