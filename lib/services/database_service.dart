import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_summary.dart';
import '../models/shopping_list.dart';
import '../models/list_item.dart';

/// Serviço responsável por todas as operações na base de dados Firestore.
/// Centralizar aqui isola a dependência do Firebase do resto da app.
class DatabaseService {
  DatabaseService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Estrutura do Firestore ---
  // users/{userId}/lists/{listId}
  // users/{userId}/summaries/{month}

  /// Referência para as listas de um utilizador
  static CollectionReference _listsRef(String userId) =>
      _db.collection('users').doc(userId).collection('lists');

  /// Referência para os resumos mensais de um utilizador
  static CollectionReference _summariesRef(String userId) =>
      _db.collection('users').doc(userId).collection('summaries');

  /// Stream de listas de compras — atualiza automaticamente quando há mudanças
  static Stream<List<ShoppingList>> getShoppingLists(String userId) {
    return _listsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ShoppingList.fromFirestore(doc))
              .toList(),
        );
  }

  /// Cria o documento do utilizador no Firestore após o registo
  static Future<void> createUserDocument({
    required String userId,
    required String email,
    required String name,
    required String location,
    required String transport,
  }) async {
    await _db.collection('users').doc(userId).set({
      'email': email,
      'name': name,
      'location': location,
      'transport': transport,
      'lifetimeSavings': 0,
      'monthlySavings': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Devolve as listas uma única vez — usado no bottom sheet do Explore
  static Future<List<ShoppingList>> getShoppingListsOnce(String userId) async {
    final snapshot = await _listsRef(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => ShoppingList.fromFirestore(doc)).toList();
  }

  /// Cria uma nova lista e devolve o ID gerado
  static Future<String> createShoppingList({
    required String userId,
    required String name,
  }) async {
    final doc = await _listsRef(userId).add({
      'name': name,
      'itemCount': 0,
      'estimatedTotal': 0.0,
      'isCompleted': false,
      'createdAt': Timestamp.now(),
      'completedAt': null,
    });
    return doc.id;
  }

  /// Elimina uma lista de compras
  static Future<void> deleteShoppingList({
    required String userId,
    required String listId,
  }) async {
    await _listsRef(userId).doc(listId).delete();
  }

  /// Busca o resumo mensal atual
  static Future<MonthlySummary?> getMonthlySummary({
    required String userId,
    required String month,
  }) async {
    final doc = await _summariesRef(userId).doc(month).get();
    if (!doc.exists) return null;
    return MonthlySummary.fromFirestore(doc.data() as Map<String, dynamic>);
  }

  /// Referência para os items de uma lista
  static CollectionReference _itemsRef(String userId, String listId) =>
      _listsRef(userId).doc(listId).collection('items');

  /// Adiciona um produto e devolve o itemId gerado
  static Future<String?> addItemToList({
    required String userId,
    required String listId,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double averagePrice,
  }) async {
    // Verifica duplicados
    final existing = await _itemsRef(
      userId,
      listId,
    ).where('productId', isEqualTo: productId).get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final doc = await _itemsRef(userId, listId).add({
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'averagePrice': averagePrice,
      'isChecked': false,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Atualiza o contador e total da lista
    await _listsRef(userId).doc(listId).update({
      'itemCount': FieldValue.increment(1),
      'estimatedTotal': FieldValue.increment(averagePrice),
    });

    return doc.id;
  }

  /// Remove um produto de uma lista
  static Future<void> removeItemFromList({
    required String userId,
    required String listId,
    required String itemId,
    required double averagePrice,
  }) async {
    await _itemsRef(userId, listId).doc(itemId).delete();

    // Atualiza o contador e total estimado da lista
    await _listsRef(userId).doc(listId).update({
      'itemCount': FieldValue.increment(-1),
      'estimatedTotal': FieldValue.increment(-averagePrice),
    });
  }

  /// Stream de items de uma lista
  static Stream<List<ListItem>> getListItems({
    required String userId,
    required String listId,
  }) {
    return _itemsRef(userId, listId)
        .orderBy('addedAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ListItem.fromFirestore(doc)).toList(),
        );
  }
}
